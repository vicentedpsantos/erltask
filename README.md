### Compiling

Run `erl -make` to compile the modules. The Emakefile defines where the BEAM files will be stored, which in this case is inside `./ebean/`.

In order to load the files in the shell, run `erl -pa ebin/`. The `-pa <directory>` option tells the Erlang VM to add that path to the places it can look for modules.

Another option is to start the shell as usual and call `make:all([load]).`. This will look for a file named `Emakefile` in the current directory, recompile it and load the new files.
