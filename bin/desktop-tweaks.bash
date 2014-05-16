#!/bin/bash

# TODO: check where local, declare MIGHT improve structure

function validate_verbosity {

    verbosity="$1"
    regex1to9=^[1-9]$

    if ! [[ $verbosity =~ $regex1to9 ]]
    then
        printf >&2 "ERROR: validate_verbosity : "
        printf >&2 "argument must be number in regex $regex1to9 not '$1'\n"
        exit 1     # abort quickly when functions not used correctly...
    fi

    return 0
}

function vprintf {

    if (( $verbose_mode < 1 ))
    then
        return 0  # return quickly...
    fi

    verbose_level="$1"
    shift

    validate_verbosity $verbose_level

    if (( $verbose_level <= $verbose_mode ))
    then
        printf "$@"
    fi

    return 0
}

function insert_content {

    array_name="$1"
    index_list="$2"

    filepath_index="$array_name[filepath]"
    file_path=${!filepath_index}
    file_path=$(eval echo ${file_path//>})
    vprintf 1 "INFO: Processing file '$file_path'\n"
    vprintf 2 "filepath  : '$file_path'\n"

    regex_index="$array_name[regex]"
    regex=${!regex_index}
    vprintf 2 "regex    : '$regex'\n"

    content_index="$array_name[content]"
    content=${!content_index}
    vprintf 2 "content   : \n"
    vprintf 2 "$content"

    file_dir=$(dirname $file_path)
    vprintf 2 "file_dir  : '$file_dir'\n"
    if [[ ! -e "$file_dir" ]]
    then
        vprintf 1 "INFO: Creating directory '$file_dir'\n"
        mkdir -p "$file_dir"
    fi

    file_name=$(basename $file_path)
    vprintf 2 "file_name : '$file_name'\n"

    if [[ ! -e "$file_path" ]]
    then
        vprintf 1 "INFO: Creating $file_name with content below:\n"
        printf "$content"
        printf "$content" >> $file_path
        vprintf 1 "INFO: Done creating $file_name\n"
    else
        vprintf 1 >&2 "WARNING: File $file_name exists, which not standard on fresh install\n"
        vprintf 1 "INFO: Testing for content starting with regex '${regex}'\n"
        if /bin/grep --quiet --regexp="$regex" "$file_path"
        then
            vprintf 1 "INFO: Did NOT modify $file_name since content start found\n"
        else
            vprintf 1 "INFO: Modified $file_name by appending content below:\n"
            printf "$content"
            printf "$content" >> $file_path
            vprintf 1 "INFO: Done modifying $file_name\n"
        fi
    fi

    return 0
}

function delete_content {

    # TODO: report how to manually fix, then actually fix

    printf >&2 "ERROR: delete_content : Not implemented!\n"
    return 1
}

# Usage: scrollbar_content "insert" | "delete"
# The "insert" argument will create the files ~/.xprofile, ~/.gtkrc-2.0 and 
# ~/.config/gtk-3.0/gtk.css which are all normally missing from brand new 
# Ubuntu installs, and adds appropriate content to files for the stepper buttons
# typically desired for for Regular scollbars.
# The "delete" argument reverses effect of a previous "insert" by removing the 
# content and deleting empty files.

function scrollbar_content {

    local modify_mode="$1"

    # double quotes on right hand side insure no bash matching, expansions
    if [[ $modify_mode != insert ]] && [[ $modify_mode != delete ]]
    then
        printf >&2 "ERROR: scrollbar_content : argument must be 'insert' or 'delete'\n"
        exit 1     # abort quickly when functions not used correctly...
    fi

    # Declare associative arrays for each file that will need to be modified.
    # Elements are: filepath (path and file name), content (the actual config 
    # file code block that needs to be inserted or deleted) and regex (search
    # string used to determine if content exists in file).

    declare -A xprofile=()
    xprofile[filepath]="~/.xprofile"
    xprofile[regex]="export\sLIBOVERLAY_SCROLLBAR=0"
    declare -A xprofile_content=()
    printf -v xprofile_content[0] "export LIBOVERLAY_SCROLLBAR=0\n"
    xprofile[content]=${xprofile_content[@]}
    vprintf 3 "xprofile filepath : ${xprofile[filepath]}\n"
    vprintf 3 "xprofile regex    : ${xprofile[regex]}\n"
    vprintf 3 "xprofile content  : \n"
    vprintf 3 "${xprofile[content]}"

    declare -A gtkrc2=()
    gtkrc2[filepath]="~/.gtkrc-2.0"
    gtkrc2[regex]="style\s\"default\"\s{"
    declare -A gtkrc2_content=()
    printf -v gtkrc2_content[0] "style \"default\" {\n"
    printf -v gtkrc2_content[1] "    engine "murrine" {\n"
    printf -v gtkrc2_content[2] "        stepperstyle = 0\n"
    printf -v gtkrc2_content[3] "    }\n"
    printf -v gtkrc2_content[4] "}\n"
    gtkrc2[content]=${gtkrc2_content[@]}
    vprintf 3 "gtkrc2 filepath : ${gtkrc2[filepath]}\n"
    vprintf 3 "gtkrc2 regex    : ${gtkrc2[regex]}\n"
    vprintf 3 "gtkrc2 content  : \n"
    vprintf 3 "${gtkrc2[content]}"

    declare -A gtkcss=()
    gtkcss[filepath]="~/.config/gtk-3.0/gtk.css"
    gtkcss[regex]=".scrollbar\s{"
    declare -A gtkcss_content=()
    printf -v gtkcss_content[0] ".scrollbar {\n"
    printf -v gtkcss_content[1] "    -GtkScrollbar-has-backward-stepper: 1;\n"
    printf -v gtkcss_content[2] "    -GtkScrollbar-has-forward-stepper: 1;\n"
    printf -v gtkcss_content[3] "    -GtkRange-slider-width: 16;\n"
    printf -v gtkcss_content[4] "    -GtkRange-stepper-size: 17;\n"
    printf -v gtkcss_content[5] "}\n"
    gtkcss[content]=${gtkcss_content[@]}
    vprintf 3 "gtkcss filepath : ${gtkcss[filepath]}\n"
    vprintf 3 "gtkcss regex    : ${gtkcss[regex]}\n"
    vprintf 3 "gtkcss content  : \n"
    vprintf 3 "${gtkcss[content]}"

    if [[ $modify_mode == insert ]]
    then
        insert_content xprofile "${!xprofile[*]}"
        insert_content gtkrc2 "${!gtkrc2[*]}"
        insert_content gtkcss "${!gtkcss[*]}"
    fi

    if [[ $modify_mode == delete ]]
    then
        delete_content xprofile "${!xprofile[*]}"
        delete_content gtkrc2 "${!gtkrc2[*]}"
        delete_content gtkcss "${!gtkcss[*]}"
    fi

    return 0
}

function validate_scrollbar_mode {

    scrollbar_mode="$1"

    # Double square brackets always needed with compound expresions.
    # When testing incoming arguments use double quotes on right hand side
    # to insure no bash pattern matching or parameter expansions happen.

    if [[ $scrollbar_mode != regular ]] && [[ $scrollbar_mode != overlay ]]
    then
        printf >&2 "ERROR: validate_scrollbar_mode : argument must be 'regular' or 'overlay'\n"
        exit 1     # abort quickly when functions not used correctly...
    fi

    return 0
}

# Usage: change_scrollbars "regular" | "overlay"
# Ubuntu 11.x and higher have Overlay type scrollbars by default, but some users
# (like the author) prefer the original look and feel of Regular scrollbars.
# change_scrollbars performs switch from Overlay scrollbars to Regular scrollbars, 
# and also takes care to add missing stepper buttons at the end of Regular bars.
# http://askubuntu.com/questions/34214/how-do-i-disable-overlay-scrollbars

function change_scrollbars {

    local scrollbar_mode="$1"
    local distrib_release="$2"

    validate_scrollbar_mode $scrollbar_mode

    if (( $(echo "$distrib_release >= 12.10" | bc -l) ))
    then
        if [[ $scrollbar_mode == regular ]]
        then
            gsettings set com.canonical.desktop.interface scrollbar-mode normal
        fi

        if [[ $scrollbar_mode == overlay ]]
        then
            gsettings reset com.canonical.desktop.interface scrollbar-mode
        fi
    else
        if [[ $scrollbar_mode == regular ]]
        then
            gsettings set org.gnome.desktop.interface ubuntu-overlay-scrollbars false
        fi

        if [[ $scrollbar_mode == overlay ]]
        then
            gsettings reset org.gnome.desktop.interface ubuntu-overlay-scrollbars
        fi
    fi

    if [[ $scrollbar_mode == regular ]]
    then
        scrollbar_content insert
    fi
 
    if [[ $scrollbar_mode == overlay ]]
    then
        scrollbar_content delete
    fi

    return 0
}

function usage {

    printf "Usage: $0 [OPTION]...\n"
    printf "Change default Ubuntu desktop scrollbars look and feel.\n"
    printf "http://askubuntu.com/questions/34214/how-do-i-disable-overlay-scrollbars\n"
    printf "Shows Bash 4.x associative array usage.\n"
    printf "More options may be added based on feedback...\n\n"
    printf "Options:\n"
    printf "    -s, --scrollbar=[regular|overlay]\n"
    printf "    -v, --verbose=NUMBER  increase output to include informational messages\n"
    printf "    -q, --quiet           reduce output to errors only\n"
    printf "    -h, --help            display this help and exit\n"
    printf "${info}Example: $0  --verbose=3 --scrollbar=regular\n"
    printf "${info}Example: $0  -v2 --scrollbar=regular\n"
    printf "${info}Example: $0  -qsregular\n"
    printf "Report bugs to <support@sturdyworks.org>\n"
    return 1
}

# getopt code based on Ubuntu 14.04 util-linux example:
# /usr/share/doc/util-linux/examples/getopt-parse.bash

function getopts_long {

    # Must declare (e.g., local) options array before the call to getopt to
    # fill array. Both local, declare have there own, seperate return status.
    # The return status (e.g., $?) from getopt call is significant. getopt 
    # will set status to non zero when user passes --junk on the command-line.
    # Having single statement like local -A options=$(getopt ... will cause
    # either the 0 != "$?" conditional just below to not fire correctly
    # or the entire eval set below to fail in a fairly spectacular way.

    local -A options=()
    options=$(getopt --shell bash --options hqs:v:: \
        --longoptions help,quiet,scrollbar:,verbose:: \
        --alternative -n 'desktop-tweaks.bash' -- "$@")
    if [[ "$?" != 0 ]]
    then
        printf >&2 "ERROR: getopt found error, terminating...\n"
        exit 1
    fi

    eval set -- "$options"

    while true ; do
	    case "$1" in
            -h | --help)
                usage
                exit 0
                ;;
		    -q | --quiet)
                quiet_mode=true
                verbose_mode=0
                shift
                ;;
		    -s | --scrollbar)
                scrollbar_mode="$2"
                validate_scrollbar_mode $scrollbar_mode
			    vprintf 1 "INFO: Option --scrollbar : argument '$2'\n"
                shift 2
                ;;
		    -v | --verbose)
			    # verbose has an optional argument. Since we are in 
                # quoted mode, an empty parameter will be generated 
                # if its optional argument is not found.
			    case "$2" in
				    "")
                        verbose_mode=1
                        shift 2
                        ;;
				    *)  verbose_mode="$2"
                        shift 2
                        ;;
			    esac
                if [[ $quiet_mode == false ]]
                then
                    vprintf 1 "INFO: Option -v|--verbose : no arg"
                    vprintf 1 " : verbose_mode=$verbose_mode\n"
                fi
                ;;
            --) # End of all options
                shift
                break
                ;;
		    *) printf >&2 "ERROR: getopt incountered internal error!\n"
                exit 1
                ;;
	    esac
    done

    # quietly! resolve issue related to user wanting verbose after quiet on command-line
    if [[ $quiet_mode == true ]]
    then
        verbose_mode=0
    fi

    # positional arguments are all that is left, but we currently do not accept them
    for positional in "$@"
    do
        printf >&2 "ERROR: getopt found positional argument : '$positional'\n"
    done
    if [[ "$@" != "" ]]
    then
        printf >&2 "ERROR: $my_name : positional arguments not accepted, terminating...\n"
        exit 1
    fi

    return 0
}

function validate_environment {

    # Need to source /etc/lsb-release for global distribution related variables
    # like $DISTRIB_ID (e.g., Ubuntu) and $DISTRIB_RELEASE (e.g., 12.04, 14.04)

    lsb_release="/etc/lsb-release"
    if [[ ! -e $lsb_release ]]
    then
        printf >&2 "ERROR: Could not determine OS distribution!\n"
        return 1
    fi

    # $DISTRIB_RELEASE variable, among others, is created by
    # next source statement, and may be referenced in main function
    # Must use dot in single command to get desired effect

    . "${lsb_release}"

    # Note: A conditional like below work fine to test but will not
    # bring lsb-release variables into our environment
    # if [[ ! -e $lsb_release ]] || 
    #    [[ $(source "${lsb_release}") && $DISTRIB_ID != "Ubuntu" ]]
    # then
    #     printf >&2 "ERROR: Please run on Ubuntu only! "
    #     printf >&2 "It's the only disto where script is tested.\n"
    #     return 1
    # fi

    if [[ $DISTRIB_ID != "Ubuntu" ]]
    then
        printf >&2 "ERROR: Please run on Ubuntu! Script was created for it.\n"
        return 1
    fi

    if [[ $(id -u) -eq 0 ]]
    then
	    printf >&2 "ERROR: Please run as regular user, not root...\n"
        return 1
    fi

    return 0
}

# In BASH, local variable scope is the current function and every 
# child function called from it, so provide a function main to 
# make it possible to utilize variable scope to solve various issues

function main {

    # Defaults for getopt and usage
    quiet_mode=false
    verbose_mode=1
    scrollbar_mode=""
    my_name=$(basename $0)

    # See what user wants, Process command-line args
    getopts_long "$@"

    # Validate that this script can run on this computer
    if ! validate_environment
    then 
        exit 1
    fi
    # validate_environment is child function and it brought distribution
    # related variables into scripts environment via . "$lsb_release"
    # Variables can now be passed on to other funcs like change_scrollbars

    # Start processing
    if [[ -n $scrollbar_mode ]]
    then
        change_scrollbars $scrollbar_mode $DISTRIB_RELEASE
    fi

    return 0
}

main "$@"
status="$?"
vprintf 1 "INFO: Done, exit status : $?\n"
exit $status
