{lib, inputs,...}:

let utils = import "${inputs.self.outPath}/lib" {inherit lib inputs;};

in utils // {

}
