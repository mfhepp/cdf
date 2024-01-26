# cdf: Change to favorite directories 

It is often time-consuming to navigate your folder structure in a Bash terminal window, even with auto-complete.

`cdf` is a simple set of utility functions that can be added to your `.bashrc` or `.bash_profile` file and will provide two quite useful new commands, `addfav` ("add to favorites") and `cdf` ("`cd` to favorite"):

## Demo

```bash
cd ~/the/windy/road/to/my/many/papers
# Add the current directory under the shortcut papers
addfav papers

cd ~/my/long/forgotten/photos
# Add the current directory under the shortcut pics
addfav pics
```

```bash
# Go to the directory via its short name from wherever you are
cdf pics
# Your are now here: ~/my/long/forgotten/photos
cdf papers
# Your are now here: ~/the/windy/road/to/my/many/papers
```

**Auto-complete works with `cdf`:** It is sufficient to type the first letters of the name of a shortcut plus the <kbd>Tab</kbd> key.

## Installation (UNIX/OSX only)

**Note:** Always backup your `~/.bashrc` or `~/.bash_profile` files prior to installing this tool. If not, please do not blame me if things go wrong.

### Simple

1. Download the tool from Github to your computer
  - **Option 1:** With `git clone`:
    ```bash
    mkdir some_directory
    cd some_directory
    git clone https://github.com/mfhepp/cdf.git
    # Git will create a folder named cdf/
    cd cdf
    ```
  - **Option 2:** Download and extract ZIP from <https://github.com/mfhepp/cdf/zipball/main>
2. Open a terminal window in the respective directory.
3. Run the install script `install.sh`
    ```bash
    # Make it executable
    chmod +x install.sh
    # Run script
    ./install.sh
    ```
4. Open a new terminal window for the changes to take effect.

### Manual

1. Create a directory in your home directory, e.g. `~/myshortcuts`, either in the OSX Finder or a terminal window with 
    ```bash
    mkdir ~/myshortcuts
    ```
    On OSX, it is better to put this somewhere under the `~/Documents` folder due to Apple's default permissions scheme.
2. Depending on your system, open either `~/.bashrc` or `~/.bash_profile` with a text editor. You may need to turn on the display of hidden files (starting with a dot) in the OSX Finder with <kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>.</kbd> (dot).
3. At the end of the `~/.bashrc` or `~/.bash_profile` file, insert the following lines:
    ```bash
    export CDFPATH=~/myshortcuts
    ```
    Replace `~/myshortcuts` with the absolute path of your chosen directory for the shortcuts (e.g. `~/Documents/myshortcuts`; note that `~/` is a shortcut for your user directory on Unix systems; you can also use the full path.). **Save the file, but keep it open.**
4. After these lines, insert the entire contents from the `cdf.sh` file from this repository. **Save and close the `~/.bashrc` or `~/.bash_profile` file.
5. Open a new terminal window or run `source ~/.bashrc` or `source ~/.bash_profile` in open terminal window to activate the changes.

## Usage

### Adding the current directory to the list of shortcuts with `addfav`

In any given directory, simply run the command

```bash
addfav NAME
```

with `NAME` being the name for the shortcut, like `project-a` or `phd`.

### Going to a directory via a given shortcut

In any given directory, simply run the command

```bash
cdf NAME
```

with `NAME` being the name for the shortcut, like `project-a` or `phd`.

### Listing available shortcuts

```bash
cdf --list
```

```bash
INFO: CDFPATH is set to /Users/foo/Documents/myshortcuts
Usage: cdf NAME

Existing directory shortcuts are:
 - photos
 - phd
 - summer-vacation
 - tax
```

You can also use `addfav --list` for the same purpose.

## Command-Line Arguments

```bash
CDF: Change to a directory via a shortcut from CDFPATH
Usage: cdf NAME

Example:
  cdf project-a: Change to the directory saved as "project-a"
  cdf --help:    Show help
  cdf --list:    List all available shortcuts

Hint: Use the TAB key for autocomplete with available shortcuts
```

```bash
ADDFAV: Adds the current directory as a shortcut to CDFPATH
Usage: addfav NAME

Example:
  addfav project-a: Add current directory as "project-a"
  addfav --help:    Show help
  addfav --list:    List all available shortcuts
```

## Technical Details

The tool creates *symbolic links* pointing to the bookmarked paths in the chosen directory. When running `cdf`, we simply execute `cd` to that symbolic link, if it exists. However, as **we want to end up in the *real* path,** it runs `cd $(realpath .)` at the very end to make sure we see the physical location and not that of the symbolic link.

It is possible to use the `CDPATH` variable for similar purposes, but this has several downsides. One could also change the behavior of the original `cd` command, but I think it is bad practice to mess around with core OS components in an intransparent way; hence the usage of a new `cdf` command.

The script tries to prevent you from creating shortcuts to locations that are themselves symbolic links. 

## Serious Warning: Be CAREFUL when DELETING symbolic links!

This tool uses [symbolic links](https://en.wikipedia.org/wiki/Symbolic_link). While this an established part of any Unix-like environment, things can go terribly wrong **when deleting symbolic links**. In the **worst case, you can delete ALL CONTENTS of the target of a symbolic link** when you are **trying to delete the symbolic link.**

For more information, read [superuser.com: Does rm -rf follow symbolic links?](https://superuser.com/questions/382314/does-rm-rf-follow-symbolic-links).

In short: **A single slash will make a huge difference!!!**

```bash
# This will DELETE ALL FILES in the directory to which 
# the symbolic link `bar` points!!!
rm -r bar/
```

```bash
# This will only delete the symbolic link `bar` itself 
# and leave the files in the link target untouched.
rm -r bar
```

**Recommendation:** When unsure, **use** a GUI tool like the **OSX Finder for deleting symbolic links.**

This warning is mostly relevant when you are trying to remove previously created symbolic links in the respective folder.

## Security

The following aspects are not specific to this tool, but likely useful background information.

If properly used, symbolic links are a pretty safe mechanism, as the access rights required are determined by the target file or directory. On most Unix systems, the permissions of the symlink do not matter; that one of the linked target are relevant. On OSX, the symlink must be readable to `readlink`. See e.g. <https://unix.stackexchange.com/questions/87200/change-permissions-for-a-symbolic-link>.

One security risk of symbolic links is that they may facilitate the discovery of high-value folders, same as they help you to access them.

Other security problems arise from symbolic links that cross boundaries of access privileges. Special **care should be taken when** creating symbolic links 
- **at locations where other users have write-access** (they could replace the link with a new one),
- **to locations where other users have write-access to** (they could change the contents or location you are actually working on or inject symbolic links that you will not identify as such.), and
- **to or at locations where users with root privileges may run executable files**.

A typically dangerous place are **/tmp** on Unix systems, and everything that is directly inside a user's directory on Apple OSX, i.e. not **below** the folders

```
Desktop/
Documents/
Downloads/
Library/
Movies/
Music/
Pictures/
```

This is because OSX, by default, grants at least read-access to all users on the given machine, via the `staff` usergroup.

If you were to use the `source` command to include the `cdf.sh` script within your `.bashrc` or `.bash_profile` file, you must make sure that the respective directory cannot be written to by other users. Otherwise, someone could inject arbitrary Bash commands into your environment. **This is why the install script instead *copies the contents of that script* to your Bash profile.**

## Credits and Acknowledgments

This tool was initially inspired by the following article:

- <https://medium.com/@marko.luksa/linux-osx-shell-trick-create-bookmarks-so-you-can-cd-directly-into-the-dirs-you-use-regularly-64003051211f>

While the proposed approach works, it has a few limitations, namely that you end up in the symbolic link directory, not the physical `realpath` thereof, which can be confusing and intransparent.

ChatGPT 4 was a great buddy and time-saver, helping me through the many pitfalls of Bash as the grand, old lady of scripting languages.

## Contact

**Univ.-Prof. Dr. Martin Hepp**

E-Business and Web Science Research Group<br>
Chair of General Management and E-Business<br>
Universität der Bundeswehr München<br>
Werner-Heisenberg-Weg 39<br>
D-85579 Neubiberg, Germany<br><br>

**eMail:** martin.hepp@unibw.de<br>
**Web:** https://www.heppnetz.de/<br>
**Web:** https://www.unibw.de/ebusiness/<br>

