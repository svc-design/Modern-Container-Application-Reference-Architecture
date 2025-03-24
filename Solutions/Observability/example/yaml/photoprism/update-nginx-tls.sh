kubectl delete  secret nginx-tls -n nginx
kubectl create secret tls nginx-tls --key=/etc/ssl/onwalk.net.key --cert=/etc/ssl/onwalk.net.pem -n nginx

kubectl delete  secret svc-plus-tls -n nginx
kubectl create secret tls svc-plus-tls --key=/etc/ssl/svc.plus.key --cert=/etc/ssl/svc.plus.pem -n nginx

kubectl delete  secret svc-ink-tls -n nginx
kubectl create secret tls svc-ink-tls --key=/etc/ssl/svc.ink.key --cert=/etc/ssl/svc.ink.pem -n nginx

kubectl delete  secret vault-tls -n vault
kubectl create secret tls vault-tls --key=/etc/ssl/onwalk.net.key --cert=/etc/ssl/onwalk.net.pem -n vault
