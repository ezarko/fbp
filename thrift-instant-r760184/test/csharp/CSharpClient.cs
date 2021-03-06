using System;
using Thrift;
using Thrift.Protocol;
using Thrift.Server;
using Thrift.Transport;


namespace CSharpTutorial
{
    public class CSharpClient
    {
        public static void Main()
        {
            try
            {
                TTransport transport = new TSocket("localhost", 9090);
                TProtocol protocol = new TBinaryProtocol(transport);
                Calculator.Client client = new Calculator.Client(protocol);

                transport.Open();

                client.ping();
                Console.WriteLine("ping()");

                int sum = client.add(1, 1);
                Console.WriteLine("1+1={0}", sum);

                Work work = new Work();

                work.op = Operation.DIVIDE;
                work.num1 = 1;
                work.num2 = 0;
                try
                {
                    int quotient = client.calculate(1, work);
                    Console.WriteLine("Whoa we can divide by 0");
                }
                catch (InvalidOperation io)
                {
                    Console.WriteLine("Invalid operation: " + io.why);
                }

                work.op = Operation.SUBTRACT;
                work.num1 = 15;
                work.num2 = 10;
                try
                {
                    int diff = client.calculate(1, work);
                    Console.WriteLine("15-10={0}", diff);
                }
                catch (InvalidOperation io)
                {
                    Console.WriteLine("Invalid operation: " + io.why);
                }

                SharedStruct log = client.getStruct(1);
                Console.WriteLine("Check log: {0}", log.value);

                transport.Close();
            }
            catch (TApplicationException x)
            {
                Console.WriteLine(x.StackTrace);
            }

        }
    }
}
