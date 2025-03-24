config:
	bash -c 'python3 scripts/init.py ./'
init: config
	bash -c 'source `pwd`/tmp-env.sh ; terraform init -migrate-state'
plan: init
	bash -c 'source `pwd`/tmp-env.sh ; terraform plan'
	bash -c 'source `pwd`/tmp-env.sh ; terraform plan -out tfplan.binary'
	bash -c 'source `pwd`/tmp-env.sh ; terraform show -json tfplan.binary > plan.json'
pre-cost: plan
	bash -c 'source `pwd`/tmp-env.sh ; infracost breakdown --path plan.json'
apply: init
	bash -c 'source `pwd`/tmp-env.sh ; terraform apply -auto-approve -lock=false'
destroy: init
	bash -c 'source `pwd`/tmp-env.sh && terraform destroy -auto-approve -lock=false'
output: init
	@bash -c 'source `pwd`/tmp-env.sh ; terraform refresh'
	@bash -c 'python3 scripts/output.py'
clean:
	@rm -vf /scripts/tmp-env.sh
	@rm -rvf .terraform*
