My poor man implementation with Amazon Alexa

Just want to try it out a little bit

## Requirement

* sox
* jq
* mpg123

The application will also require some of the defaultly available packages on
every Major linux distros

* curl
* grep

### Mac OS X

Install with Homebrew
```bash
brew install sox jq mpg123
```

### Debian/Ubuntu

```bash
sudo apt-get install -y sox jq mpg123
```

### CentOS, Fedora project, Archlinux

```bash
sudo yum install -y sox jq mpg123
```

## How to run it

To use Alexa Voice service, you will need to register a device/application with
Amazon and put the credential you got back to the ```all_in_one.sh``` script

#### Register an application with Amazon Developer

Navigate to ```https://developer.amazon.com/``` and login (register for an
account if you haven't got any)

Click on tab **Alexa** on the nav bar and select **Alexa Voice Service**

Click on the down arrow next to **Register a Product Type** button and select
**Device**

