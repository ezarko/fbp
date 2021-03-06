#include <concurrency/ThreadManager.h>
#include <concurrency/PosixThreadFactory.h>
#include <concurrency/Monitor.h>
#include <concurrency/Util.h>
#include <concurrency/Mutex.h>
#include <protocol/TBinaryProtocol.h>
#include <server/TSimpleServer.h>
#include <server/TThreadPoolServer.h>
#include <server/TThreadedServer.h>
#include <transport/TServerSocket.h>
#include <transport/TSocket.h>
#include <transport/TTransportUtils.h>
#include <transport/TFileTransport.h>
#include <TLogging.h>

#include "Service.h"

#include <iostream>
#include <set>
#include <stdexcept>
#include <sstream>

#include <map>
#include <ext/hash_map>
using __gnu_cxx::hash_map;
using __gnu_cxx::hash;

using namespace std;
using namespace boost;

using namespace apache::thrift;
using namespace apache::thrift::protocol;
using namespace apache::thrift::transport;
using namespace apache::thrift::server;
using namespace apache::thrift::concurrency;

using namespace test::stress;

struct eqstr {
  bool operator()(const char* s1, const char* s2) const {
    return strcmp(s1, s2) == 0;
  }
};

struct ltstr {
  bool operator()(const char* s1, const char* s2) const {
    return strcmp(s1, s2) < 0;
  }
};


// typedef hash_map<const char*, int, hash<const char*>, eqstr> count_map;
typedef map<const char*, int, ltstr> count_map;

class Server : public ServiceIf {
 public:
  Server() {}

  void count(const char* method) {
    Guard m(lock_);
    int ct = counts_[method];
    counts_[method] = ++ct;
  }

  void echoVoid() {
    count("echoVoid");
    return;
  }

  count_map getCount() {
    Guard m(lock_);
    return counts_;
  }

  int8_t echoByte(const int8_t arg) {return arg;}
  int32_t echoI32(const int32_t arg) {return arg;}
  int64_t echoI64(const int64_t arg) {return arg;}
  void echoString(string& out, const string &arg) {
    if (arg != "hello") {
      T_ERROR_ABORT("WRONG STRING!!!!");
    }
    out = arg;
  }
  void echoList(vector<int8_t> &out, const vector<int8_t> &arg) { out = arg; }
  void echoSet(set<int8_t> &out, const set<int8_t> &arg) { out = arg; }
  void echoMap(map<int8_t, int8_t> &out, const map<int8_t, int8_t> &arg) { out = arg; }

private:
  count_map counts_;
  Mutex lock_;

};

class ClientThread: public Runnable {
public:

  ClientThread(shared_ptr<TTransport>transport, shared_ptr<ServiceClient> client, Monitor& monitor, size_t& workerCount, size_t loopCount, TType loopType) :
    _transport(transport),
    _client(client),
    _monitor(monitor),
    _workerCount(workerCount),
    _loopCount(loopCount),
    _loopType(loopType)
  {}

  void run() {

    // Wait for all worker threads to start

    {Synchronized s(_monitor);
      while(_workerCount == 0) {
        _monitor.wait();
      }
    }

    _startTime = Util::currentTime();

    _transport->open();

    switch(_loopType) {
    case T_VOID: loopEchoVoid(); break;
    case T_BYTE: loopEchoByte(); break;
    case T_I32: loopEchoI32(); break;
    case T_I64: loopEchoI64(); break;
    case T_STRING: loopEchoString(); break;
    default: cerr << "Unexpected loop type" << _loopType << endl; break;
    }

    _endTime = Util::currentTime();

    _transport->close();

    _done = true;

    {Synchronized s(_monitor);

      _workerCount--;

      if (_workerCount == 0) {

        _monitor.notify();
      }
    }
  }

  void loopEchoVoid() {
    for (size_t ix = 0; ix < _loopCount; ix++) {
      _client->echoVoid();
    }
  }

  void loopEchoByte() {
    for (size_t ix = 0; ix < _loopCount; ix++) {
      int8_t arg = 1;
      int8_t result;
      result =_client->echoByte(arg);
      assert(result == arg);
    }
  }

  void loopEchoI32() {
    for (size_t ix = 0; ix < _loopCount; ix++) {
      int32_t arg = 1;
      int32_t result;
      result =_client->echoI32(arg);
      assert(result == arg);
    }
  }

  void loopEchoI64() {
    for (size_t ix = 0; ix < _loopCount; ix++) {
      int64_t arg = 1;
      int64_t result;
      result =_client->echoI64(arg);
      assert(result == arg);
    }
  }

  void loopEchoString() {
    for (size_t ix = 0; ix < _loopCount; ix++) {
      string arg = "hello";
      string result;
      _client->echoString(result, arg);
      assert(result == arg);
    }
  }

  shared_ptr<TTransport> _transport;
  shared_ptr<ServiceClient> _client;
  Monitor& _monitor;
  size_t& _workerCount;
  size_t _loopCount;
  TType _loopType;
  long long _startTime;
  long long _endTime;
  bool _done;
  Monitor _sleep;
};


int main(int argc, char **argv) {

  int port = 9091;
  string serverType = "thread-pool";
  string protocolType = "binary";
  size_t workerCount = 4;
  size_t clientCount = 20;
  size_t loopCount = 50000;
  TType loopType  = T_VOID;
  string callName = "echoVoid";
  bool runServer = true;
  bool logRequests = false;
  string requestLogPath = "./requestlog.tlog";
  bool replayRequests = false;

  ostringstream usage;

  usage <<
    argv[0] << " [--port=<port number>] [--server] [--server-type=<server-type>] [--protocol-type=<protocol-type>] [--workers=<worker-count>] [--clients=<client-count>] [--loop=<loop-count>]" << endl <<
    "\tclients        Number of client threads to create - 0 implies no clients, i.e. server only.  Default is " << clientCount << endl <<
    "\thelp           Prints this help text." << endl <<
    "\tcall           Service method to call.  Default is " << callName << endl <<
    "\tloop           The number of remote thrift calls each client makes.  Default is " << loopCount << endl <<
    "\tport           The port the server and clients should bind to for thrift network connections.  Default is " << port << endl <<
    "\tserver         Run the Thrift server in this process.  Default is " << runServer << endl <<
    "\tserver-type    Type of server, \"simple\" or \"thread-pool\".  Default is " << serverType << endl <<
    "\tprotocol-type  Type of protocol, \"binary\", \"ascii\", or \"xml\".  Default is " << protocolType << endl <<
    "\tlog-request    Log all request to ./requestlog.tlog. Default is " << logRequests << endl <<
    "\treplay-request Replay requests from log file (./requestlog.tlog) Default is " << replayRequests << endl <<
    "\tworkers        Number of thread pools workers.  Only valid for thread-pool server type.  Default is " << workerCount << endl;


  map<string, string>  args;

  for (int ix = 1; ix < argc; ix++) {

    string arg(argv[ix]);

    if (arg.compare(0,2, "--") == 0) {

      size_t end = arg.find_first_of("=", 2);

      string key = string(arg, 2, end - 2);

      if (end != string::npos) {
        args[key] = string(arg, end + 1);
      } else {
        args[key] = "true";
      }
    } else {
      throw invalid_argument("Unexcepted command line token: "+arg);
    }
  }

  try {

    if (!args["clients"].empty()) {
      clientCount = atoi(args["clients"].c_str());
    }

    if (!args["help"].empty()) {
      cerr << usage.str();
      return 0;
    }

    if (!args["loop"].empty()) {
      loopCount = atoi(args["loop"].c_str());
    }

    if (!args["call"].empty()) {
      callName = args["call"];
    }

    if (!args["port"].empty()) {
      port = atoi(args["port"].c_str());
    }

    if (!args["server"].empty()) {
      runServer = args["server"] == "true";
    }

    if (!args["log-request"].empty()) {
      logRequests = args["log-request"] == "true";
    }

    if (!args["replay-request"].empty()) {
      replayRequests = args["replay-request"] == "true";
    }

    if (!args["server-type"].empty()) {
      serverType = args["server-type"];

      if (serverType == "simple") {

      } else if (serverType == "thread-pool") {

      } else if (serverType == "threaded") {

      } else {

        throw invalid_argument("Unknown server type "+serverType);
      }
    }

    if (!args["workers"].empty()) {
      workerCount = atoi(args["workers"].c_str());
    }

  } catch(exception& e) {
    cerr << e.what() << endl;
    cerr << usage;
  }

  shared_ptr<PosixThreadFactory> threadFactory = shared_ptr<PosixThreadFactory>(new PosixThreadFactory());

  // Dispatcher
  shared_ptr<Server> serviceHandler(new Server());

  if (replayRequests) {
    shared_ptr<Server> serviceHandler(new Server());
    shared_ptr<ServiceProcessor> serviceProcessor(new ServiceProcessor(serviceHandler));

    // Transports
    shared_ptr<TFileTransport> fileTransport(new TFileTransport(requestLogPath));
    fileTransport->setChunkSize(2 * 1024 * 1024);
    fileTransport->setMaxEventSize(1024 * 16);
    fileTransport->seekToEnd();

    // Protocol Factory
    shared_ptr<TProtocolFactory> protocolFactory(new TBinaryProtocolFactory());

    TFileProcessor fileProcessor(serviceProcessor,
                                 protocolFactory,
                                 fileTransport);

    fileProcessor.process(0, true);
    exit(0);
  }


  if (runServer) {

    shared_ptr<ServiceProcessor> serviceProcessor(new ServiceProcessor(serviceHandler));

    // Transport
    shared_ptr<TServerSocket> serverSocket(new TServerSocket(port));

    // Transport Factory
    shared_ptr<TTransportFactory> transportFactory(new TBufferedTransportFactory());

    // Protocol Factory
    shared_ptr<TProtocolFactory> protocolFactory(new TBinaryProtocolFactory());

    if (logRequests) {
      // initialize the log file
      shared_ptr<TFileTransport> fileTransport(new TFileTransport(requestLogPath));
      fileTransport->setChunkSize(2 * 1024 * 1024);
      fileTransport->setMaxEventSize(1024 * 16);

      transportFactory =
        shared_ptr<TTransportFactory>(new TPipedTransportFactory(fileTransport));
    }

    shared_ptr<Thread> serverThread;

    if (serverType == "simple") {

      serverThread = threadFactory->newThread(shared_ptr<TServer>(new TSimpleServer(serviceProcessor, serverSocket, transportFactory, protocolFactory)));

    } else if (serverType == "threaded") {

      serverThread = threadFactory->newThread(shared_ptr<TServer>(new TThreadedServer(serviceProcessor, serverSocket, transportFactory, protocolFactory)));

    } else if (serverType == "thread-pool") {

      shared_ptr<ThreadManager> threadManager = ThreadManager::newSimpleThreadManager(workerCount);

      threadManager->threadFactory(threadFactory);
      threadManager->start();
      serverThread = threadFactory->newThread(shared_ptr<TServer>(new TThreadPoolServer(serviceProcessor, serverSocket, transportFactory, protocolFactory, threadManager)));
    }

    cerr << "Starting the server on port " << port << endl;

    serverThread->start();

    // If we aren't running clients, just wait forever for external clients

    if (clientCount == 0) {
      serverThread->join();
    }
  }

  if (clientCount > 0) {

    Monitor monitor;

    size_t threadCount = 0;

    set<shared_ptr<Thread> > clientThreads;

    if (callName == "echoVoid") { loopType = T_VOID;}
    else if (callName == "echoByte") { loopType = T_BYTE;}
    else if (callName == "echoI32") { loopType = T_I32;}
    else if (callName == "echoI64") { loopType = T_I64;}
    else if (callName == "echoString") { loopType = T_STRING;}
    else {throw invalid_argument("Unknown service call "+callName);}

    for (size_t ix = 0; ix < clientCount; ix++) {

      shared_ptr<TSocket> socket(new TSocket("127.0.01", port));
      shared_ptr<TBufferedTransport> bufferedSocket(new TBufferedTransport(socket, 2048));
      shared_ptr<TProtocol> protocol(new TBinaryProtocol(bufferedSocket));
      shared_ptr<ServiceClient> serviceClient(new ServiceClient(protocol));

      clientThreads.insert(threadFactory->newThread(shared_ptr<ClientThread>(new ClientThread(socket, serviceClient, monitor, threadCount, loopCount, loopType))));
    }

    for (std::set<shared_ptr<Thread> >::const_iterator thread = clientThreads.begin(); thread != clientThreads.end(); thread++) {
      (*thread)->start();
    }

    long long time00;
    long long time01;

    {Synchronized s(monitor);
      threadCount = clientCount;

      cerr << "Launch "<< clientCount << " client threads" << endl;

      time00 =  Util::currentTime();

      monitor.notifyAll();

      while(threadCount > 0) {
        monitor.wait();
      }

      time01 =  Util::currentTime();
    }

    long long firstTime = 9223372036854775807LL;
    long long lastTime = 0;

    double averageTime = 0;
    long long minTime = 9223372036854775807LL;
    long long maxTime = 0;

    for (set<shared_ptr<Thread> >::iterator ix = clientThreads.begin(); ix != clientThreads.end(); ix++) {

      shared_ptr<ClientThread> client = dynamic_pointer_cast<ClientThread>((*ix)->runnable());

      long long delta = client->_endTime - client->_startTime;

      assert(delta > 0);

      if (client->_startTime < firstTime) {
        firstTime = client->_startTime;
      }

      if (client->_endTime > lastTime) {
        lastTime = client->_endTime;
      }

      if (delta < minTime) {
        minTime = delta;
      }

      if (delta > maxTime) {
        maxTime = delta;
      }

      averageTime+= delta;
    }

    averageTime /= clientCount;


    cout <<  "workers :" << workerCount << ", client : " << clientCount << ", loops : " << loopCount << ", rate : " << (clientCount * loopCount * 1000) / ((double)(time01 - time00)) << endl;

    count_map count = serviceHandler->getCount();
    count_map::iterator iter;
    for (iter = count.begin(); iter != count.end(); ++iter) {
      printf("%s => %d\n", iter->first, iter->second);
    }
    cerr << "done." << endl;
  }

  return 0;
}
