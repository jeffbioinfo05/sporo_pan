# Ansible — Provisionamento do PC

## Para PC novo na rede

1. Instalar Ansible na máquina de controle (não precisa no PC alvo):
```bash
sudo apt install ansible -y
```

2. Editar `inventory.ini` com o IP do PC novo

3. Garantir acesso SSH sem senha:
```bash
ssh-copy-id jeff@192.168.1.X
```

4. Rodar o playbook:
```bash
ansible-playbook -i ansible/inventory.ini ansible/playbook.yml
```

## Para PC local (reinstalação)
```bash
ansible-playbook -i ansible/inventory.ini ansible/playbook.yml -c local
```

## Editar variáveis
Abra `playbook.yml` e ajuste a seção `vars`:
- `lab_repo`: endereço do seu repositório GitHub/GitLab
- `hd_mount`: ponto de montagem do HD externo
