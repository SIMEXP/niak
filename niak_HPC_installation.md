## Instalation
The most straing foward way of installing NIAK on an HPC system is trough its [Singularity]( http://singularity.lbl.gov/) image. [Singularity]( http://singularity.lbl.gov/) is a linux conatainer system designed around the notion of extreme mobility of compute and reproducible science.

Fist you need to ask your system administrator to install [Singularity](http://singularity.lbl.gov/) on the HPC. We recomand [release](http://singularity.lbl.gov/all-release) 2.2 or higher.

The administrator decides in the installation which part of the HPC file system will be accessible to the Singularity containers, make sure that the patition where your data lives is include in the "bind path".

Once Singularity is installed, running NIAK is straight forward. Just get the [latest niak_singularity.tgz release](https://github.com/SIMEXP/niak/releases/latest) from the [NIAK github page](https://github.com/SIMEXP/niak/release) and decompress the tar ball on your computer:

```
tar -zxvf niak_singularity.tgz
```
you can test that niak is working by typing:

```
cd niak_singularity
./psom_console.sh niak-VERSION-NAME-AND-NUMBER.img
```
Depending on the local file system setup, it can take a couple of seconds to load niak the first time. Wait a bit, you should now be in an octave console.
You are now ready to run our [tutorials](http://niak.simexp-lab.org/niak_tutorials.html):

## Basic Configuration
By default the installation runs only on the host where it was installed with only one core. To change that, open the `psom_gb_vars_local.m` with your favorite editor change `gb_psom_mode` from `session` to `singularity` mode:
```octave
%gb_psom_mode = 'session';
gb_psom_mode = 'singularity';
```
Right now the `singularity` mode only works with system using the `qsub` command. Any options needed by your local HPC to run the qsub command can be added to `gb_psom_qsub_options`. For example, on compute Canada Guillmin HPC, ones need to state his group id in every qsub call. This requirement is met by adding the following in `psom_gb_vars_local.m`
```octave
gb_psom_qsub_options = '-A my-group-id';.
```

## More configutations
The tar ball comes with a `psom.conf` file. This configuration can be stored in `/etc/psom.conf`, along in the `psom_console` directory or in `${HOME}/.config/psom/psom.conf`. Note that the file are loaded in that order. So a user can overwrite the system `/etc/psom.conf` in ``${HOME}/.config/psom/psom.conf`. If you do not have root access to the system, the same logic applies to the a `psom.conf` file living in the `psom_console.sh` directory.

The configuration is use to tell "psom_console" where to look for the `psom_gb_vars_local.m` files and the `niak-VERSION-NAME-AND-NUMBER.img` images. The default is to find then at the same location than `psom_console` itself. You also need to set the `PSOM_SINGULARITY_OPTIONS` variable so that directory other than the host `${HOME}` and `/tmp` are accessible to the NIAK software. For example, if you need to mount a `/scratch` partitions you can uncomment the line:
```
PSOM_SINGULARITY_OPTIONS='-B /scratch'.
```  

Note that `PSOM_SINGULARITY_IMAGES_PATH` works in the same way as $PATH does. One can add acessible images in many directories like this:
```
PSOM_SINGULARITY_IMAGES_PATH=/usr/local/niak_singularity_images/:$HOME/my_niak_images
```
 then,
```
psom_console.sh -l
```
will list all the images stored in these directories. Note that all images should preferably have different names.
