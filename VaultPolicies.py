#! python
import subprocess
def runcmd(cmd):
    try:
        print('Trying %s' % cmd)
        output = subprocess.check_output(cmd, shell=True, stderr=subprocess.STDOUT)
        print('Success %s' % cmd)
        return output
    except subprocess.CalledProcessError:
        print ('Execution of "%s" failed!\n' % cmd)
        sys.exit(1)

def list2file(list, file):
    with open(file, 'w') as f:
        for item in list:
            f.write()
#chain= ['vault policy  write --tls-skip-verify admin admin-policy.hcl',
'vault policy  list --tls-skip-verify',
'vault policy read --tls-skip-verify admin',
'vault policy read --tls-skip-verify admin > admin-policy.hcl.out',
'diff admin-policy.hcl admin-policy.hcl.out'
]
for cmd in chain:
#    runcmd(cmd)

cmd='vault token create --tls-skip-verify -format=json -policy="admin" | jq -r ".auth.client_token"'
output=runcmd(cmd)
# Verify
#output=output.strip('\n');
# if (output != 'create, delete, sudo, update'):
#         print('Warn:',output)
#         sys.exit(1)

import json
with open('developers.json', 'r') as f:
    a = json.loads(f.read())

with open('developers.json', 'w') as f:
    f.write(json.dumps(a))

#Now read the file back into a Python list object
