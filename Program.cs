﻿using System.Threading.Tasks;
using System.Collections.ObjectModel;
using System.Collections.Generic;
using System.Collections;
using System.IO;
using Pulumi;
using System.Management.Automation;

// Used https://github.com/aws/aws-lambda-dotnet/blob/master/Libraries/src/Amazon.Lambda.PowerShellHost/PowerShellFunctionHost.cs as an inspiration

class Program
{
    static Task<int> Main()
    {

        return Deployment.RunAsync(() => {
            using PowerShell powershellInstance = PowerShell.Create();
            string psScriptPath = Path.Combine(Directory.GetCurrentDirectory(),"pulumi.ps1");
            System.Console.WriteLine("Running Powershell Script " + psScriptPath);
            powershellInstance.AddCommand("Set-ExecutionPolicy").AddArgument("RemoteSigned").AddParameter("Scope","CurrentUser");
            Collection<PSObject> psOutput = powershellInstance.AddScript(psScriptPath).Invoke();

            if (powershellInstance.Streams.Error.Count > 0) {
                System.Console.WriteLine("Powershell script returned {0} errors", powershellInstance.Streams.Error.Count);
                System.Console.WriteLine("First Error: " + powershellInstance.Streams.Error[0].Exception);
                throw powershellInstance.Streams.Error[0].Exception;
            }

            var myRawOutput = psOutput[0].BaseObject as Hashtable;
            //TODO: Code here that should validate it is a hashtable output and provide a nice warning if not
            //TODO: Should also allow for all iDictionary types if Powershell sends one down the pipe

            //Convert Hashtable to pulumi-required dictionary without using Linq
            Dictionary<string,object> pulumiOutput = new Dictionary<string,object>();
            foreach (string key in myRawOutput.Keys) {
                pulumiOutput.Add(key, myRawOutput[key]);
            }
            return pulumiOutput;
        });
    }
}