[Original Link](https://bitnuts.de/articles/raspbian_self_cleaning_guest_account.html)

The Raspberry Pi is a great little computer which can be used in many situations. Unfortunately the default setup comes with an admin account which is not suitable, if you'd like to have the Pi used by third parties. Luckily Linux is a multi-user system, so you can just create a guest account:

```
sudo adduser guest
```

One drawback is, that this user account is not self cleaning and keeps all the information the last guest user has created. One option to solve the problem is to backup the guest user account and re-create it on next reboot. So we first configure the guest account with all the options and configuration settings you'd like it to have. Then back it up like this:

```
sudo chown -R pi /home/guest
sudo cp -f -r /home/guest/ /home/pi/guest/
sudo chown -R guest /home/pi/guest
```

Now open up `/etc/rc.local`

```
sudo nano /etc/rc.local
```

Add the following commands into the file and save it.

```
# clean guest account after reboot
sudo chown -R pi /home/guest
sudo rm -f -r /home/guest
sudo cp -f -r /home/pi/guest /home/
sudo chown -R guest /home/guest
```

Here we go, you now have a self cleaning guest account which will be turned into its original state after reboot. Well, of course a guest user could still leave traces and files.

You should remove username from group sudo:

```
sudo gpasswd -d guest sudo
```

You could create a more restricted user group and add the guest user into it. I will upgrade this post if I have more information on this
