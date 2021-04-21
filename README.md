# Paster

Quickly paste items into the clipboard from an easy to resize panel.<br>
Execute arbitrary shell commands or open URLs through easy configuration switches.<br>
Add an item from the clipboard using the '+' button.<br>
Remove an item by right-clicking on it.<br>

<p align="center"><img src="screenshots/mainwindow.png"></p>

## Version History

* v1.2 - added support for executing arbitrary shell commands through the '! ' config prefix;
* v1.1 - added support for reading the initial clips off an optional configuration file;<br>
           - adds support for remembering window position between sessions (Windows only).
* v1.0 - initial release.

## Downloads
You can <b>download</b> the latest release for <b>Windows</b> 32 and 64 bits as a portable, standalone executable [HERE](https://github.com/DexterLagan/paster/releases).

## Optional Configuration 

* A config file (**paster.conf**) can optionally be provided, and paster will create buttons for each string in it;
* Secrets can be partially hidden if their config line starts with '* ';
* arbitrary shell commands can be launched if specified by config lines starting with '! '.

Example:
<pre>
! https://www.some-url.com
* some-secret-text
some other item
more items
* some other secret
more regular clips
! firefox
</pre>

## License

NewIDE is free software; see [LICENSE](https://github.com/DexterLagan/paster/blob/main/LICENSE) for more details.
