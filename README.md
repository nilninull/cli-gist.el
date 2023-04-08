# cli-gist.el

Display the Github Gist with the [GitHub CLI][gh] command.

There are already several Emacs packages with similar functionality, but they are frequently unavailable due to GitHub changes.

This package is simply built using Github's official command line tools, so it may be available for a long time in the future.

## Usage

```M-x list-gist```

### Predefined Keys

| Key         | Description                             |
|-------------|-----------------------------------------|
| W           | Open the Gist web page under the cursor |
| E or Return | Edit the Gist under the cursor          |
| D or Delete | Delete the Gist under the cursor        |

### Other interactive functions
| Function              | Description                                       |
|-----------------------|---------------------------------------------------|
| ```cli-gist-create``` | Create a new Gist by ```gh gist create``` command |

[gh]: https://github.com/cli/cli
