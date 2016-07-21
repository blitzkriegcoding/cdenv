# Simple virtual environment Manager
#
# A set of bash/zsh functions that provide simple virtual environment
# capabilities. To install, just copy this file into your home directory and
# add the following to your .bashrc or .zshrc file:

# if [[ -f "$HOME/.cdenv/cdenv.sh" ]]; then
#     source "$HOME/.cdenv/cdenv.sh"

#     # Uncomment the following line if you want virtual environments
#     # activated/deactivted as you cd into/out of them.
#     # alias cd="_cdenv_cd"

#     # Uncomment the following line if you want to try to check for a
#     # virtual environment in the current directory (and activate it)
#     # whenever a new shell session is created.
#     # cdenv activate
# fi

# This script provides a new function called cdenv that can be used to
# activtate and deactivate virtual environments. A virtual environment is any
# directory that contains a `.activate` and/or `.deactivate` file within it.
# To activate a virtual environment, simply cd into it and call the `cdenv
# activate` command. This will check the current directory for a `.activate`
# file, and if one exists, source it. To deactivate the environment, simply
# call the 'cdenv deactivate' command.

# In addition to altering the PATH variable, cdenv also supports setup
# and teardown functionality as well. if a .activate file is found in
# the directory, it will source it when the virtual environment is
# activated. Likewise, if a .deactivate file is found, it will source
# it upon deactivation. These files allow you to do extra
# setup/teardown to your environment as needed.
#
# Created by Christopher Roach <croach@madebyglitch.com>


_cdenv_help() {
    echo
    echo "Simple Virtual Environment Manager"
    echo
    echo "Usage:"
    echo "    cdenv help             Show this message"
    echo "    cdenv activate         Activate the virtual environment in the current directory"
    echo "    cdenv deactivate       Deactivate the current virtual environment"
    echo "    cdenv home             Change directory to the current virtual environement's directory"
    echo
}

# This function is meant to replace the builtin 'cd' function. Using
# this will make sure that virtual environments are automatically
# activated and deactivated as you cd into and out of them. Not
# everyone likes the idea of aliasing builtin functions to custom
# functions though, so I've intentionally left this step out. If,
# however, you'd like to have this functionality, simply add the
# following line to your .bashrc or .zshrc script right after you
# source this file:
#
# alias cd="_cdenv_cd"
#
# Otherwise, you can use the cdenv command to activate/deactivate
# virtual environments.
#
_cdenv_cd() {
    builtin cd "$@"

    # Make sure that an environment does exist and that the new
    # directory is not a subdirectory of the environment directory and
    # that the auto-deactivate feature is turned on before
    # deactivating the current virtual environment
    if _cdenv_exists  && ! _cdenv_subdirectory && _cdenv_auto_deactivate ; then
        cdenv deactivate
    fi

    # Make sure a virtual environment doesn't already exist before creating a
    # new one.
    if ! _cdenv_exists ; then
        cdenv activate

		# Set the auto-deactivate variable to make sure the virtual
		# environment is deactivated when we leave the parent
		# directory
		export CDENV_AUTO_DEACTIVATE=true
    fi
}


# Returns true if a virtual environment is currently active
_cdenv_exists() {
	[ -n "${CDENV_HOME+set}" ];
}

# Returns true if the auto-deactivate feature is on
_cdenv_auto_deactivate() {
	[ -n "${CDENV_AUTO_DEACTIVATE}" ];
}

# Returns true if the current directory is a subdirectory of the
# current virtual envirionment's home directory
_cdenv_subdirectory() {
    local child="$PWD"
    local parent="$CDENV_HOME"
	[ "${child##${parent}}" != "$child" ];
}

# Returns the name of the current virtual environment
_cdenv_name() {
	basename "$CDENV_HOME"
}

# Activates a new environment
_cdenv_activate() {
    # Check if the directory we've cd'ed into is a virtual environment
    # directory (i.e., it contains a .activate file) before trying to
    # activate it
    if [ -f ".activate" ]; then

        # An environment is essentially nothing more than an
        # environment variable (CDENV_HOME) pointing to the parent
        # directory of our virtual environment. Create the variable
        # and point it to $PWD.
        export CDENV_HOME="$PWD"

        # Update the prompt to show that we are in a virtual
        # environment
        export CDENV_OLD_PS1="$PS1"
        export PS1="($(_cdenv_name))$PS1"

		# Activate the new virtual environment
		source .activate
    fi
}

# Deactivates the current environment
_cdenv_deactivate() {
    # Make sure that an environment does exist before we try to
    # deactivate it
    if _cdenv_exists ; then

		echo "Deactivating ($(_cdenv_name))"

        # Run the deactivation script if it exists
        if [[ -e "$CDENV_HOME/.deactivate" ]]; then
            source "$CDENV_HOME/.deactivate"
        fi

        # Revert the prompt
        export PS1="$CDENV_OLD_PS1"

        # Destroy the environment
        unset CDENV_HOME
        unset CDENV_OLD_PS1
		unset CDENV_AUTO_DEACTIVATE
    fi
}


cdenv() {
    if [ $# -lt 1 ]; then
        cdenv help
        return
    fi

    case $1 in
        "help" )
            _cdenv_help
            ;;
        "activate" )
            _cdenv_activate
            ;;
        "deactivate" )
            _cdenv_deactivate
            ;;
        "home" )
            builtin cd "$CDENV_HOME"
            ;;
        * )
            _cdenv_cd "$@"
            ;;
    esac
}


# Setup bash and zsh command completion
_cdenv_command_completion() {
    local cur
    local commands="help home activate deactivate ls"

    cur="${COMP_WORDS[COMP_CWORD]}"

    # An array storing the possible completions
    COMPREPLY=( $(compgen -W "${commands}" -- "${cur}") )

    return 0
}

# complete is a bash builtin, but recent versions of ZSH come with a
# function called bashcompinit that will create the complete function
# in ZSH. If the user is in ZSH, load and run bashcompinit before
# calling the complete.
if [[ -n ${ZSH_VERSION-} ]]; then
    autoload -U +X bashcompinit && bashcompinit
fi
complete -o default -o nospace -F _cdenv_command_completion cdenv