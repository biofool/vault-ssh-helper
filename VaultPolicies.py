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
