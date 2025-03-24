locals {
  config = yamldecode(file("../envs/{{ vars.config }}"))
}
