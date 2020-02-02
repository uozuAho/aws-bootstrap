# AWS bootstrap

Working through https://gumroad.com/l/aws-good-parts

# todo

- try example codedeploy: https://docs.aws.amazon.com/codedeploy/latest/userguide/instances-ec2-create-cloudformation-template.html

- move infra code to subdir
    - Figure out how to specify non-default buildspec location. AWS docs
      suck/are wrong?

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