# AWS bootstrap

Working through https://gumroad.com/l/aws-good-parts

# The current infrastructure

Under infra/ directory. To deploy, run infra/deploy_infra.sh. See the top
of that file for required external config (eg. github + aws credentials).

- CodePipeline
  - Runs from github webhook
  - Deploys node server onto EC2 instances
- 2x environments: staging and prod
  - VPC
    - Multiple subnets in difference AZs
    - DNS with manually created domain (Route53)
    - ALB / ELB  todo: which is it???
    - HTTPS with manually created cert (ACM)
    - ASG
      - N x EC2
        - Runs CodeDeploy agent + node server

# book errors

- npm build wasn't documented in the book. I added it as a dummy step.

- CodeDeploy doesn't preserve symlinks. The app uses node_modules/.bin/pm2
  to run, which is a symlink to node_modules/pm2/bin/pm2. pm2 doesn't work
  if the file is simply copied to node_modules/.bin/pm2 as a regular file
  (not a symlink), which is what CodeDeploy does. I added a post-install
  hook to appspec to replace the copied file with a symlink.

# notes

- at end of first deployment using CodeDeploy: all files are in the root
  directory, start/stop service scripts only work in the deployed environment.
  This is hardly a well structured, portable solution

- It's not clear when the pipeline fails that it's due to the CD agent not
  coming up on the EC2 instance. I mistakenly put the CD agent install command
  in the wrong spot in main.yml, which caused the agent to not be installed.
  See commit `655ad35`.

- Getting appspec wrong can mean you need to tear the entire stack down and
  rebuild. This takes ages, is there no faster way to do this? ECS/EKS is
  looking very attractive right now.

- Nested stack parameters should be strings (?). When creating the nested stack
  in this project, I initially had the EC2AMI paramter defined as
  `AWS::SSM::Parameter::Value<AWS::EC2::Image::Id>` in both templates. This
  caused a 'unable to fetch parameter from parameter store' when creating the
  staging resource. Changing the parameter type to `String` in the nested stack
  solved the problem. See commit `1f54c5a`.

# todo, not in book

- automate certificate renewal
- use ECS/EKS/Fargate
