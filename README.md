Build
-----

To build the project simply run `build.cmd`.
You have to have [NuGet command-line tool](http://www.nuget.org/downloads) (`nuget.exe`) available either in the `.nuget` sub-folder or anywhere in the PATH.
One can also pass additional command-line parameters (following to the MSBuild syntax) to the script.

Alternatively (or for advanced operations) open the command prompt and execute the following commands from the root of the repository:

    $> nuget restore
    $> msbuild build.proj [options]

By default a WebDeploy profile named `Package` will be used while building.
To use another existing profile (e.g. `Local`) issue the following statement from the command line passing the name of that profile as the value of the `PublishProfile` variable:

    $> build.cmd /p:PublishProfile=Local

Or, when using MSBuild directly:

    $> msbuild build.proj /p:PublishProfile=Local
