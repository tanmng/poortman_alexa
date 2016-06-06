My poor man implementation with Amazon Alexa

Just want to try it out a little bit

## Requirement

* sox [http://sox.sourceforge.net/](http://sox.sourceforge.net/)
* jq [https://stedolan.github.io/jq/](https://stedolan.github.io/jq/)
* mpg123 [https://www.mpg123.de/](https://www.mpg123.de/)

The application will also require some of the defaultly available packages on
every Major linux distros

* curl
* grep

### Mac OS X

Install with [Homebrew](http://brew.sh/)
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

## Basic understanding

We have to run our application (in this case, the ```all_in_one.sh``` script) as
a device in Amazon Developer. The device will have a **Security Profile** with a unique ID,
whenever we want to use this _device_ we will have to **Authorize** it (basically
telling Amazon that "Yes, I know and trust this device, let it access your API
with my account, please!").

First, we will need to set up a device and associate with it a security profile.
The process describe below will guide you through that set up.

Whenever we **Authorize** the app, Amazon will return your browser to a **Return URL** of your choice.
We can leverate this to get the returned authorization code from AWS (via ```$_GET``` in the script listening on the return URL)
However, since this app run locally, we will just set it to a dummy address.

After we receive the **Authorization code** from the Return URL, you will use to
to request for an **Access token**, ```all_in_one.sh``` will later use that
token to call Alexa Voice Service API.

**Note**: Because the **Access token** is only valid for one hour (a security
feature, in case your token got leaked), you will need to **Refresh** that
token. You can set up a cronjob to do so. The details is described below.

## Settings up the app

To use Alexa Voice service, you will need to register a device/application with
Amazon and put the credential you got back to the ```all_in_one.sh``` script

#### Register a device with Amazon Developer

##### Process

Navigate to [https://developer.amazon.com/](https://developer.amazon.com/) and login (register for an
account if you haven't got any)

Click on tab **Alexa** on the nav bar

![Alexa tab in Amazon Developer site](/readme_images/Screen Shot 2016-06-06 at 5.16.28 PM.png?raw=true)

Select **Alexa Voice Service**

![Alexa Voice Service page](/readme_images/Screen Shot 2016-06-06 at 5.31.33 PM.png?raw=true)

Click on the down arrow next to **Register a Product Type** button and select
**Device**
![First screen of creating new device](/readme_images/Screen Shot 2016-06-06 at 5.17.47 PM.png?raw=true)

In the next screen, enter a **Device Type ID** and a **Display Name**

**Note**: your **Device Type ID** will have to be unique, please make sure to
use a unique name (eg: a random string), instead of some general name like ```test device```
![Alexa Voice Service page](/readme_images/Screen Shot 2016-06-06 at 5.34.30 PM.png?raw=true)

In the next screen, select **Create a new profile** and enter a name
\+ description for the new profile
![Alexa Voice Service page](/readme_images/Screen Shot 2016-06-06 at 5.39.56 PM.png?raw=true)

In the next screen, take note of the 3 fields 
* **Security Profile ID**
* **Client ID**
* **Client Secret**

![Alexa Voice Service page](/readme_images/Screen Shot 2016-06-06 at 5.46.00 PM.png?raw=true)

In the next screen, put in any details you want
![Alexa Voice Service page](/readme_images/Screen Shot 2016-06-06 at 5.50.46 PM.png?raw=true)

Select to disable Amazon Music (you can try to enable it and develop it, I don
have an account in Amazon Music so I decided to leave it as **No**)
![Alexa Voice Service page](/readme_images/Screen Shot 2016-06-06 at 5.53.13 PM.png?raw=true)

Click **Submit** and you will be done with setting up new device.

#### Enable callback URL

After the previous step, you will get back to listing of devices in your Amazon
Developer account. Click on the name of the device you just created (in this
example: **RandomizedHere**)
![Alexa Voice Service page](/readme_images/Screen Shot 2016-06-06 at 5.57.22 PM.png?raw=true)

Select **Security Profile** and change to **Web Settings**
![Alexa Voice Service page](/readme_images/Screen Shot 2016-06-06 at 6.02.01 PM.png?raw=true)

Click on **Edit**, then **Add Another** and input ```https://localhost:9745``` for both **Allowed Origins** 

Click on **Add Another** of **Allowed Return URLs** and input ```https://localhost:9745/authresponse```
![Alexa Voice Service page](/readme_images/Screen Shot 2016-06-06 at 6.06.54 PM.png?raw=true)

Click on **Save** and you are done.

#### Edit ```all_in_one.sh``` 

Open ```all_in_one.sh``` in your favourite text editor and put in the **Device ID**, security profile's **Client ID** and **Client Secret**
from previous steps
![Alexa Voice Service page](/readme_images/Screen Shot 2016-06-06 at 6.19.18 PM.png?raw=true)

**You are now ready to rock**

#### Set ```all_in_one.sh``` to $PATH and make some aliases (optional)

For easier use, you can put ```all_in_one.sh``` in a directory in your $PATH and
make some aliases for it.

## Using the app

First, you will need to request for **Authentication code**

Run 
```bash
./all_in_one.sh 1
```
![Alexa Voice Service page](/readme_images/Screen Shot 2016-06-06 at 6.24.39 PM.png?raw=true)

A new tab of your default browser will open and navigate to Amazon to request
access code, login if you're not already, click on **Okay** to allow your security profile to access Alexa
Voice Service
![Alexa Voice Service page](/readme_images/Screen Shot 2016-06-06 at 6.25.30 PM.png?raw=true)

Amazon will return you to your **Return URL**, which is [https://localhost:9745/authresponse](https://localhost:9745/authresponse)
and add the code to that URL. Take note of that code 
(click on the address bar and copy the value between ```code=``` and ```&scope=```, in the image bellow, the code is **ANOcTfvcMbfUxBfAGaqt**)
![Alexa Voice Service page](/readme_images/Screen Shot 2016-06-06 at 6.27.58 PM.png?raw=true)

Run
```bash
./all_in_one.sh 2 [ACCESS CODE FROM BEFORE]
```

eg:
```bash
./all_in_one.sh 2 ANOcTfvcMbfUxBfAGaqt
```
![Result of all_in_one.sh 2 ANOcTfvcMbfUxBfAGaqt](/readme_images/Screen Shot 2016-06-06 at 6.32.03 PM.png?raw=true)

After this, you can use alexa.

Run
```bash
./all_in_one.sh 4
```

Speak whatever you want (eg: "Who are you?"), press ```Ctrl-C``` (to end ```sox```), wait
for ```curl``` to request to Amazon API endpoint, and then listen to Alexa's
reponse.
![Alexa Voice Service page](/readme_images/.png?raw=true)


Congrats, you just interacted with Amazon Alexa.


As explained above, your **access token** is only valid for one hour, so you
will need to refresh it, use 
```bash
./all_in_one.sh 3
```
to do so
![Result of all_in_one.sh 3](/readme_images/Screen Shot 2016-06-06 at 6.41.23 PM.png?raw=true)







![Alexa Voice Service page](/readme_images/.png?raw=true)
![Alexa Voice Service page](/readme_images/.png?raw=true)
![Alexa Voice Service page](/readme_images/.png?raw=true)
![Alexa Voice Service page](/readme_images/.png?raw=true)
![Alexa Voice Service page](/readme_images/.png?raw=true)
![Alexa Voice Service page](/readme_images/.png?raw=true)
