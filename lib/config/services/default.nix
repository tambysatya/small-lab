{lib,...}:

{
  generators = {
    step-ca = (import ./step-ca {inherit lib;}).generator;
  };
}
