[Original Link](https://thepihut.com/blogs/raspberry-pi-tutorials/how-to-change-the-default-account-username-and-password)

By default your raspberry pi pi comes with an account `pi` with the password `raspberry`. For security reasons it's probably a good idea to change the password, but you may also wish to change the username as well. There are a couple of different ways to change the default username but I found the following method the easiest. 

In order to change the username `pi` we will have to log in a the root user since it's not possible to rename an account while your logged into it. To log in as root user first we have to enable it, to do so type the following command whilst logged in as the default pi user:

```
sudo passwd root
```

Choose a secure password for the root user. You can disable the root account later if you wish.

Now logout of the user pi using the command:

```
logout
```

And then logout back in as the user `root` using the password you just created. Now we can rename the the default pi user name. The following method renames the user `pi` to `newname`, replace this with whatever you want. Type the command:

```
usermod -l newname pi
```

Now the user name has been changed the user's home directory name should also be changed to

reflect the new login name:

```
usermod -m -d /home/newname newname
```

Now logout and login back in as newname. You can change the default password from raspberry to something more secure by typing following command and entering a new password when prompted:

```
passwd
```

If you wish you can disable the root user account again but first double check newname still has 'sudo' privileges. Check the following update command works:

```
sudo apt-get update
```

If it works then you can disable the root account by locking the password:

```
sudo passwd -l root
```

And that's it