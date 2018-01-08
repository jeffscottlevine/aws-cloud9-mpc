# Introduction

This repo contains the files associated with the django polling tutorial that can be found at https://www.djangoproject.com/.  I decided to name this project, MyPollingCompany, hence the name "mpc."  I am currently writing this to operate udner the following platforms.

1. Amazon Linux 1 with the Cloud9 IDE on its own EC2 instance.

# Instructions for Amazon Linux 1 with the Cloud9 IDE on its own EC2 instance

1.  Create an AWS Cloud9 environment in its own instance, not an ssh instance.
2.  Open the environment.
3.  Go to the existing terminal window or open up a new bash window.
4.  cd $HOME/environment
5.  git config --global user.name "your name"
6.  git config --global user.email "your email"
7.  git clone "the https URL from github"
8.  cd mpc
9.  ./amazon_linux1_cloud9_setup.sh
10. Follow the instructions displayed at the conclusion of the script.`

# Notes

1. The files may contain multiple versions of content.  I did this so I could keep track of what changed throughout the tutorial.

2. I am usinmg MySQL for the backend.

# Security Considerations

1. This is a demo and is not built with strong security in mind.
2. The passwords are short and are generated with pwgen.
3. Passwords are used on command lines - a strong no no!

# Attribution

1. The background image is from Kelli Tungay and came from https://unsplash.com/photos/RAVdOqWXPvg.
