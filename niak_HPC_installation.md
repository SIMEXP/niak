# Installation
The most straight forward way of installing NIAK on an HPC system is trough its [Singularity]( http://singularity.lbl.gov/) image. [Singularity]( http://singularity.lbl.gov/) is a Linux container system "designed around the notion of extreme mobility of compute and reproducible science".

First you need to ask your system administrator to install [Singularity](http://singularity.lbl.gov/) on the HPC. We recommend [release](http://singularity.lbl.gov/all-release) 2.2 or higher.

The administrator decides in the installation which part of the HPC file system will be accessible to users in the Singularity containers, make sure that the partition where your data lives is include in the "bind path".

Once Singularity is installed, running NIAK is straight forward. Just get the [latest niak_singularity.tgz release](https://github.com/SIMEXP/niak/releases/latest) from the [NIAK github page](https://github.com/SIMEXP/niak) and decompress the tar ball on your computer:

```
tar -zxvf niak_singularity.tgz
```
you can test that the installation worked by typing:

```
cd niak_singularity
./psom_console.sh niak-VERSION-NAME-AND-NUMBER.img
```
Depending on the local file system setup, it can take a couple of seconds to NIAK the first time. Wait a bit, you should now be in an octave console with a fully functional NIAK installation.
You are now ready to run our [tutorials](http://niak.simexp-lab.org/niak_tutorials.html) on the local host.

## Basic HPC Configuration
By default the installation runs only on the host where it was installed and with only one core. To change that, open the `psom_gb_vars_local.m` with your favorite editor change `gb_psom_mode` from `session` to `singularity` mode:
```octave
%gb_psom_mode = 'session';
gb_psom_mode = 'singularity';
```
Right now the `singularity` mode only works with system using the `qsub` command. Any options needed by your local HPC to run the qsub command can be added to `gb_psom_qsub_options`. For example, on compute Canada Guillmin HPC, ones need to state his group id in every qsub call. This requirement is met by adding the following in `psom_gb_vars_local.m`
```octave
gb_psom_qsub_options = '-A my-guillimin-group-id';.
```

With this minimal configuration, you should be able to use the full power of your HPC!

## More configurations
The tar ball comes with a `psom.conf` file. This configuration can be stored in three places. In `/etc/psom.conf`, along with the `psom_console.sh` file (that is how it is shipped in the tar ball) or here: `${HOME}/.config/psom/psom.conf`. Note that the file are loaded in that order. So a user can overwrite the system `/etc/psom.conf` in ``${HOME}/.config/psom/psom.conf`. If you do not have root access to the system, a `psom.conf` file living in the `psom_console.sh` directory can act as a system wide config.

The configuration tells "psom_console.sh" where to look for the `psom_gb_vars_local.m` file and the `niak-VERSION-NAME-AND-NUMBER.img` images. The default is to find them at the same location than `psom_console.sh` itself. You also need to set the `PSOM_SINGULARITY_OPTIONS` variable so that directory other than the host `${HOME}` and `/tmp` are accessible to the NIAK software. For example, if you need to mount the `/scratch` directory, you can uncomment the line:
```
PSOM_SINGULARITY_OPTIONS='-B /scratch'.
```  

Note that `PSOM_SINGULARITY_IMAGES_PATH` works in the same way as $PATH does. One can add valid NIAK images in many directories like this:
```
PSOM_SINGULARITY_IMAGES_PATH=/usr/local/niak_singularity_images/:$HOME/my_niak_images
```
 then,
```
psom_console.sh -l
```
will list all the images stored in these directories. Note that all images should preferably have different names.

# Adding new images on the system

Many NIAK versions can be accessible at the same time on a HPC system. Once psom_console has been installed. Just download and decompress any on the `niak-*.img.tgz` tar ball found in the [release section of the NIAK github page](https://github.com/SIMEXP/niak/releases) in a path included in `PSOM_SINGULARITY_IMAGES_PATH`. It is now accessible in `psom_console`.
