只加密 private_key 字段
1. 原始 vpn-keys.yaml
yaml
keys:
  - name: master-1
    private_key: <master_private_key>
    public_key: <master_public_key>
2. 使用 ansible-vault encrypt_string 加密 private_key

- ansible-vault encrypt_string 'private-key-xxxx' --name 'private_key'
- ansible-vault encrypt_string 'public_key-xxxx' --name 'public_key'

示例输出（加密后是 YAML 结构）：

yaml
private_key: !vault |
          $ANSIBLE_VAULT;1.1;AES256
          62326432376162336462343864333933356363373235623262306463326432363737623732613763
          3962613662616565393463343030653733623066626137610a313465323462623261303031323337
