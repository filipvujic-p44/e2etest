#!/bin/bash
script_name="e2etest"
version="v1.3.4"
author="Filip Vujic"
last_updated="02-Apr-2025"
repo_owner="filipvujic-p44"
repo_name="e2etest"
repo="https://github.com/$repo_owner/$repo_name"



###########################################################################################
###################################### Info and help ######################################
###########################################################################################



# Help text
help_text=$(cat <<EOL
HELP:
-------------

Info:
-----
    version: $version
    author: $author
    last updated: $last_updated
    github: $repo

    This script is a tool for easier test calls for ltl.

Options:
--------
    fh-test.sh [-v | --version] [-h | --help] [--install] [--install-y] [--uninstall] [--chk-install]
	           [--chk-for-updates] [--auto-chk-for-updates-off] [--auto-chk-for-updates-on]
	           [-t | --token] [-s | --scac] [-g | --group] [--unit] [--acc-code]
               [-n | --refnum] [--pro] [--bol] [-c | --config] [-q | --quiet] [-a | --all]
               [-r] [-x] [--rating] [--dispatch] [--tracking]

Options (details):
------------------
    general:
        -v | --version                    Display script version and author.
        -h | --help                       Display help and usage info.
        --install                         Install script to use from anywhere in terminal.
        --install-y                       Install with preapproved dependencies and run 'gcloud auth login' after installation.
        --uninstall                       Remove changes made during install (except dependencies).
        --chk-install                     Check if script and dependencies are installed correctly.
        --chk-for-updates                 Check for new script versions.
        --auto-chk-for-updates-off        Turn off automatic check for updates (default state).
        --auto-chk-for-updates-on         Turn on automatic check for updates (checks on every run).
        --generate-env-file               Generate '.env_e2etest' in current folder.
        -t | --token                      Update token value.
        -s | --scac                       Update scac value.
        -g | --group                      Update group value.
        -n | --refnum                     Update reference number (identifier).
        --unit                            Update handling unit supported.
        --acc-code                        Update accessorial code used for testing charge codes.
        --pronum                          Update pro number (identifier).
        --bolnum                          Update bill of lading number (identifier).
        --ponum                           Update purchase order number (identifier).
        --pro                             Set identifier type to pro.
        --bol                             Set identifier type to bill of lading.
        -c | --config                     Display set parameters.
        -q | --quiet                      Display only curl status code.
        -a | --all                        Run all scenarios.
        -x                                Exclude specified scenarios.
        -r                                Run specified scenarios.
        -o                                Generate output folder with curls.
        --rating                          Run all rating scenarios.
        --dispatch                        Run all dispatch scenarios.
        --tracking                        Run all tracking scenarios.
EOL
)



############################################################################################
###################################### Vars and flags ######################################
############################################################################################



do_install=false
do_install_y=false
do_uninstall=false
do_chk_install_=false
# ref_chk_for_updates (do not change comment)
flg_chk_for_updates=false
flg_generate_env_file=false

flg_args_passed=false

flg_use_quiet_mode=false
flg_custom=false
flg_all=false
flg_run_rating=false
flg_run_dispatch=false
flg_run_tracking=false
total_status_output_length=75
flg_generate_output=false
#ref_token
token="token"
#ref_scac
scac=""
#ref_account_group
account_group="PAID_INT_TEST"
#ref_unit_supported
flg_unit_supported=false
# ref_acc_code
acc_code="INPU"
#ref_identifier_type
identifier_type="PRO"
#ref_pro_num
pro_num="003381632"
#ref_bol_num
bol_num="003381632"
#ref_po_num
po_num="003381632"
helper_doc_file_name=helper_doc.txt

scenarios_to_run=()
scenarios_to_exclude=()



# Load local .env_e2etest file
if [ -e ".env_e2etest" ]; then
    flg_args_passed=true
    source .env_e2etest

    echo "Info: Loading values from .env_e2etest file."

    # Load use quiet mode value
    if [ ! -z "$USE_QUIET_MODE" ]; then
        flg_use_quiet_mode="$USE_QUIET_MODE"
    fi

    # Load run all value
    if [ ! -z "$RUN_ALL" ]; then
        flg_all="$RUN_ALL"
    fi

    # Load run rating value
    if [ ! -z "$RUN_RATING" ]; then
        flg_run_rating="$RUN_RATING"
    fi

    # Load run dispatch value
    if [ ! -z "$RUN_DISPATCH" ]; then
        flg_run_dispatch="$RUN_DISPATCH"
    fi

    # Load run tracking value
    if [ ! -z "$RUN_TRACKING" ]; then
        flg_run_tracking="$RUN_TRACKING"
    fi

    # Load generate output value
    if [ ! -z "$GENERATE_OUTPUT" ]; then
        flg_generate_output="$GENERATE_OUTPUT"
    fi

	# Load token value
    if [ ! -z "$TOKEN" ]; then
        token="$TOKEN"
    fi

	# Load scac value
    if [ ! -z "$SCAC" ]; then
        scac="$SCAC"
    fi

	# Load account group value
    if [ ! -z "$ACCOUNT_GROUP" ]; then
        account_group="$ACCOUNT_GROUP"
    fi

	# Load unit supported value
    if [ ! -z "$UNIT_SUPPORTED" ]; then
        flg_unit_supported="$UNIT_SUPPORTED"
    fi

	# Load acc code value
    if [ ! -z "$ACC_CODE" ]; then
        acc_code="$ACC_CODE"
    fi

	# Load identifier type value
    if [ ! -z "$IDENTIFIER_TYPE" ]; then
        identifier_type="$IDENTIFIER_TYPE"
    fi

	# Load pro num value
    if [ ! -z "$PRO_NUM" ]; then
        pro_num="$PRO_NUM"
    fi

	# Load bol num value
    if [ ! -z "$BOL_NUM" ]; then
        bol_num="$BOL_NUM"
    fi

	# Load po num value
    if [ ! -z "$PO_NUM" ]; then
        po_num="$PO_NUM"
    fi

	# Load helper doc file name value
    if [ ! -z "$HELPER_DOC_FILE_NAME" ]; then
        helper_doc_file_name="$HELPER_DOC_FILE_NAME"
    fi

fi



# Helper functions

print_status_code() {
    local status_code=$1
    
    if [[ $status_code =~ ^2[0-9]{2}$ ]]; then
        echo -e "\e[32m$status_code ✅\e[0m"  # Green for 2xx
    else
        echo -e "\e[31m$status_code ❌\e[0m"  # Red for non-2xx
    fi
}

print_error() {
    local err_msg=$1
    echo -e "\e[31mError: $err_msg\e[0m"  # Red for non-2xx
}



# Check if any args are passed to the script
if [ -z "$1" ]; then
	print_error "No arguments passed!"
	exit 0
else
	flg_args_passed=true
fi




while [ "$1" != "" ] || [ "$#" -gt 0 ]; do

    case "$1" in
		-v | --version)
            echo "e2etest version: $version"
            echo "author: $author"
            echo "last updated: $last_updated"
            echo "github: $repo"
            exit 0
            ;;
        -h | --help)
            echo "$help_text"
            exit 0
            ;;
		--install)
            do_install=true
            ;;
        --install-y)
            do_install_y=true
            ;;
        --uninstall)
            do_uninstall=true
            ;;
        --chk-install)
            do_chk_install=true
            ;;
		--chk-for-updates)
            flg_chk_for_updates=true
            ;;
        --auto-chk-for-updates-off)
            ref_line_number=$(grep -n "ref_chk_for_updates*" "$0" | head -n1 | cut -d':' -f1)
            line_number=$(grep -n "flg_chk_for_updates=" "$0" | head -n1 | cut -d':' -f1)
            if [ "$((line_number - ref_line_number))" -eq 1 ]; then
                sed -i "${line_number}s/flg_chk_for_updates=true/flg_chk_for_updates=false/" "$0"
                echo "Info: Auto check for updates turned off."	
            fi
            exit 0
            ;;
        --auto-chk-for-updates-on)
            ref_line_number=$(grep -n "ref_chk_for_updates*" "$0" | head -n1 | cut -d':' -f1)
            line_number=$(grep -n "flg_chk_for_updates=" "$0" | head -n1 | cut -d':' -f1)
            if [ "$((line_number - ref_line_number))" -eq 1 ]; then
                sed -i "${line_number}s/flg_chk_for_updates=false/flg_chk_for_updates=true/" "$0"
                echo "Info: Auto check for updates turned on."
            fi
            exit 0
            ;;
		--generate-env-file)
            flg_generate_env_file=true
            ;;
        -t | --token)
            ref_line_number=$(grep -n "ref_token*" "$0" | head -n1 | cut -d':' -f1)
            line_number=$(grep -n "token=" "$0" | head -n1 | cut -d':' -f1)
            if [ "$((line_number - ref_line_number))" -eq 1 ]; then
                sed -i "${line_number}s/^token=.*/token=\"$2\"/" "$0"
                echo "Info: Token updated."	
			shift 1
            fi
            ;;
        -s | --scac)
            ref_line_number=$(grep -n "ref_scac*" "$0" | head -n1 | cut -d':' -f1)
            line_number=$(grep -n "scac=" "$0" | head -n1 | cut -d':' -f1)
            if [ "$((line_number - ref_line_number))" -eq 1 ]; then
                sed -i "${line_number}s/^scac=.*/scac=\"${2^^}\"/" "$0"
                echo "Info: Scac updated."	
			shift 1
            fi
            ;;
        -g | --group)
            ref_line_number=$(grep -n "ref_account_group*" "$0" | head -n1 | cut -d':' -f1)
            line_number=$(grep -n "account_group=" "$0" | head -n1 | cut -d':' -f1)
            if [ "$((line_number - ref_line_number))" -eq 1 ]; then
                sed -i "${line_number}s/^account_group=.*/account_group=\"$2\"/" "$0"
                echo "Info: Account group updated."	
			shift 1
            fi
            ;;
        --unit)
            ref_line_number=$(grep -n "ref_unit_supported*" "$0" | head -n1 | cut -d':' -f1)
            line_number=$(grep -n "flg_unit_supported=" "$0" | head -n1 | cut -d':' -f1)
            if [[ $((line_number - ref_line_number)) -eq 1 && "$2" == "true" || "$2" == "false" ]]; then
                sed -i "${line_number}s/^flg_unit_supported=.*/flg_unit_supported=$2/" "$0"
                echo "Info: Unit handling updated."
			shift 1
            fi
          	;;
        --acc-code)
            ref_line_number=$(grep -n "ref_acc_code*" "$0" | head -n1 | cut -d':' -f1)
            line_number=$(grep -n "acc_code=" "$0" | head -n1 | cut -d':' -f1)
            if [ "$((line_number - ref_line_number))" -eq 1 ]; then
                sed -i "${line_number}s/^acc_code=.*/acc_code=\"$2\"/" "$0"
                echo "Info: Accessorial code updated."	
			shift 1
            fi
          	;;
        --pronum)
            ref_line_number=$(grep -n "ref_pro_num*" "$0" | head -n1 | cut -d':' -f1)
            line_number=$(grep -n "pro_num=" "$0" | head -n1 | cut -d':' -f1)
            if [ "$((line_number - ref_line_number))" -eq 1 ]; then
                sed -i "${line_number}s/^pro_num=.*/pro_num=\"$2\"/" "$0"
                echo "Info: Pro number updated."	
			shift 1
            fi
          	;;
        --bolnum)
            ref_line_number=$(grep -n "ref_bol_num*" "$0" | head -n1 | cut -d':' -f1)
            line_number=$(grep -n "bol_num=" "$0" | head -n1 | cut -d':' -f1)
            if [ "$((line_number - ref_line_number))" -eq 1 ]; then
                sed -i "${line_number}s/^bol_num=.*/bol_num=\"$2\"/" "$0"
                echo "Info: Bill of lading number updated."	
			shift 1
            fi
          	;;
        --ponum)
            ref_line_number=$(grep -n "ref_po_num*" "$0" | head -n1 | cut -d':' -f1)
            line_number=$(grep -n "po_num=" "$0" | head -n1 | cut -d':' -f1)
            if [ "$((line_number - ref_line_number))" -eq 1 ]; then
                sed -i "${line_number}s/^po_num=.*/po_num=\"$2\"/" "$0"
                echo "Info: Purchase order number updated."	
			shift 1
            fi
          	;;
        --pro)
            ref_line_number=$(grep -n "ref_identifier_type*" "$0" | head -n1 | cut -d':' -f1)
            line_number=$(grep -n "identifier_type=" "$0" | head -n1 | cut -d':' -f1)
            if [ "$((line_number - ref_line_number))" -eq 1 ]; then
                sed -i "${line_number}s/^identifier_type=.*/identifier_type=\"PRO\"/" "$0"
                echo "Info: Identifier set to PRO."	
            fi
            ;;
        --bol)
            ref_line_number=$(grep -n "ref_identifier_type*" "$0" | head -n1 | cut -d':' -f1)
            line_number=$(grep -n "identifier_type=" "$0" | head -n1 | cut -d':' -f1)
            if [ "$((line_number - ref_line_number))" -eq 1 ]; then
                sed -i "${line_number}s/^identifier_type=.*/identifier_type=\"BILL_OF_LADING\"/" "$0"
                echo "Info: Identifier set to BILL_OF_LADING."	
            fi
            ;;
        -c | --config)
			echo "Token ------------------- $token"
			echo "Scac -------------------- $scac"
			echo "Account group ----------- $account_group"
			echo "Unit handling ----------- $flg_unit_supported"
			echo "Accessorial code -------- $acc_code"
			echo "Identifier type --------- $identifier_type"
			echo "Pro number -------------- $pro_num"
			echo "Bill of lading number --- $bol_num"
			echo "Purchase order number --- $po_num"
			echo "Logs url ---------------- $logs_url"
            exit 0
            ;;
        -q | --quiet)
        	flg_use_quiet_mode=true
        	;;
        -a | --all)
        	flg_all=true
        	;;
		-r)
			shift  # Move to the next argument (first scenario number)
			while [[ $# -gt 0 && "$1" != -* ]]; do
				scenarios_to_run+=("$1")  # Add each scenario to the array
				shift
			done
			continue  # Skip automatic shift below, we already moved the pointer
			;;
		-x)
			shift  # Move to the next argument (first scenario number)
			while [[ $# -gt 0 && "$1" != -* ]]; do
				scenarios_to_exclude+=("$1")  # Add each scenario to the array
				shift
			done
			continue  # Skip automatic shift below, we already moved the pointer
			;;
		-o)
			flg_generate_output=true
			;;
        --rating)
        	flg_run_rating=true
        	;;
        --dispatch)
        	flg_run_dispatch=true
        	;;
        --tracking)
        	flg_run_tracking=true
        	;;
		*)
			echo "Error: Unknown argument '$1'!"
			;;
    esac
    # Since this default shift exists, all flag handling shifts are decreased by 1
    shift
done


# Check if curl is installed
check_curl_installed() {
    command -v curl &>/dev/null
}

# Check if jq is installed
check_jq_installed() {
    command -v jq &>/dev/null
}

# Check if git is installed
check_git_installed() {
    command -v git &>/dev/null
}

check_bash_completion_installed() {
    if dpkg -l | grep -q "bash-completion"; then
        return 0
    fi
    return 1
}




# Check if all necessary changes are done during installation
check_installation() {
    local cnt_missing=0
    if check_curl_installed; then
        echo "Info: curl ------------------- OK."
    else
        echo "Error: curl ------------------ NOT FOUND."
        ((cnt_missing++))
    fi

    if check_jq_installed; then
        echo "Info: jq --------------------- OK."
    else
        echo "Error: jq -------------------- NOT FOUND."
        ((cnt_missing++))
    fi

    if check_git_installed; then
        echo "Info: git -------------------- OK."
    else
        echo "Error: git ------------------- NOT FOUND."
        ((cnt_missing++))
    fi

    if check_bash_completion_installed; then
        echo "Info: bash-completion -------- OK."
    else
        echo "Error: bash-completion ------- NOT FOUND."
        ((cnt_missing++))
    fi
        
    if [ -d ~/e2etest ] && [ -f ~/e2etest/main/e2etest.sh ] && [ -f ~/e2etest/util/autocomplete_e2etest.sh ]; then
        echo "Info: ~/e2etest/ ------------- OK."
    else
        echo "Error: ~/e2etest/ ------------ NOT OK."
        ((cnt_missing++))
    fi

    if grep -q "# e2etest script" ~/.bashrc && grep -q 'export PATH=$PATH:~/e2etest/main' ~/.bashrc &&
        grep -q "source ~/e2etest/util/autocomplete_e2etest.sh" ~/.bashrc; then
        echo "Info: ~/.bashrc -------------- OK."
    else
        echo "Error: ~/.bashrc ------------- NOT OK."
        ((cnt_missing++))
    fi	

    if [ "$cnt_missing" -gt "0" ]; then
        echo "Error: Problems found. Use '--install' or '--install-y' to (re)install the script." >&2
        return 1
    fi
    return 0
}



# Check if the required number of args is passed to a function
# $1 - required number of args
# $2 - all passed args
check_args() {
        local parent_func="${FUNCNAME[1]}"
        local required_number_of_args=$1
        shift;
        local total_number_of_args=$#
        local args=$@
        if [ $total_number_of_args == 0 ] || [ -z $total_number_of_args ]; then
            echo "Error: No arguments provided!" >&2
            return 1
        fi
        if [ $total_number_of_args -ne $required_number_of_args ]; then
            echo "Error: Function '$parent_func' required $required_number_of_args arguments but $total_number_of_args provided!" >&2
            return 1
        fi
}


# Check if all dependencies are installed
check_dependencies() {
    if ! check_curl_installed; then
        echo "Info: curl is not installed. Installing updates may not work properly."
    fi

    if ! check_jq_installed; then
        echo "Info: jq is not installed. JSON formatting may not work properly."
    fi

    if ! check_git_installed; then
        echo "Info: Git is not installed. Syncing with GitHub may not work properly."
    fi

    if ! check_bash_completion_installed; then
        echo "Info: Bash-completion is not installed. It is not required, but you won't have command completion."
    fi
}





#################################################################################################
###################################### Install / Uninstall functions ############################
#################################################################################################



# Main installation function
install_script() {
    echo "Info: Installing e2etest..."
    script_directory="$(dirname "$(readlink -f "$0")")"
    # Check if requirements installed
    if ! check_curl_installed || ! check_jq_installed || ! check_git_installed || ! check_bash_completion_installed; then
        install_dependencies
    fi
    # Check if script already installed
    if [ -d ~/e2etest ] && [ -f ~/e2etest/main/e2etest.sh ] && [ -f ~/e2etest/util/autocomplete_e2etest.sh ] &&
    grep -q "# e2etest script" ~/.bashrc && grep -q 'export PATH=$PATH:~/e2etest/main' ~/.bashrc &&
    grep -q "source ~/e2etest/util/autocomplete_e2etest.sh" ~/.bashrc; then
        echo "Info: Script already installed at '~/e2etest' folder."
        echo "Q: Do you want to reinstall e2etest? (Y/n):"
        read do_reinstall
        if [ "${do_reinstall,,}" == "n" ]; then
            echo "Info: Exited installation process. No changes made."
            exit 0
        fi
    fi
    # Clean up possible leftovers or previous installation
    clean_up_installation
    # Set up e2etest home folder
    echo "Info: Setting up '~/e2etest/' directory..."
    mkdir ~/e2etest
    mkdir ~/e2etest/main
    mkdir ~/e2etest/util
    cp $script_directory/e2etest.sh ~/e2etest/main
    # Generate autocomplete script
    generate_autocomplete_script
    echo "Info: Setting up '~/e2etest/' directory completed."
    # Set up bashrc inserts
    echo "Info: Adding paths to '~/.bashrc'..."
    echo "# e2etest script" >> ~/.bashrc
    echo 'export PATH=$PATH:~/e2etest/main' >> ~/.bashrc
    echo "source ~/e2etest/util/autocomplete_e2etest.sh" >> ~/.bashrc
    echo "Info: Paths added to '~/.bashrc'."
    # Print success message
    echo "Info: Success. Script installed in '~/e2etest/' folder."
    # If '--install-y' was used, set up gcloud auth
    if [ "$do_install_y" == "true" ]; then
        echo "Info: Setting up GCloud CLI login..."
        echo "Q: Input your p44 email:"
        read email
        gcloud auth login $email
        if gcloud auth list | grep -q "$email"; then
            echo "Info: Logged in to GCloud CLI."
            echo "Info: Use '--help-gcloud-cli' for more info."
        else
            echo "Error: Something went wrong during GCloud CLI login attempt." >&2
        fi
    else
        echo "Info: Use 'gcloud auth login my.email@project44.com' to login to GCloud CLI."
        echo "Info: Use 'gcloud auth list' to check if you are logged in."
        echo "Info: Use '--help-gcloud-cli' for more info."
    fi
    echo "Info: Run 'source ~/.bashrc' to apply changes in current session."
    echo "Info: Local file './e2etest.sh' is no longer needed."
    echo "Info: Use '-h' or '--help' to get started."
    exit 0
}



install_curl() {
    echo "Info: Installing curl..."
    if [ "$do_install_y" == "true" ]; then
        sudo apt install -y curl
    else
        sudo apt install curl
    fi
    echo "Info: curl installed."
    
}


install_jq() {
    echo "Info: Installing jq..."
    if [ "$do_install_y" == "true" ]; then
        sudo apt install -y jq
    else
        sudo apt install jq
    fi
    echo "Info: jq installed."
    
}


install_git() {
    echo "Info: Installing git..."
    if [ "$do_install_y" == "true" ]; then
        sudo apt install -y git
    else
        sudo apt install git
    fi
    echo "Info: Git installed."
}

install_bash_completion() {
    echo "Info: Installing bash-completion..."
    if [ "$do_install_y" == "true" ]; then
        sudo apt install -y bash-completion
    else
        sudo apt install bash-completion
    fi
    echo "Info: Bash-completion installed."
}

install_dependencies() {
    sudo apt update
    # Check if curl is installed
    if ! check_curl_installed; then
        install_curl
    fi
    
    # Check if jq is installed
    if ! check_jq_installed; then
        install_jq
    fi
    
    # Check if git is installed
    if ! check_git_installed; then
        install_git
    fi

    # Check if bash-completion installed
    if ! check_bash_completion_installed; then
        install_bash_completion
    fi
}


# Cleans up existing installation and leftover files/changes
clean_up_installation() {
    echo "Info: Cleaning up existing files/changes..."
    if [ -d ~/e2etest ]; then
        rm  ~/e2etest/main/*
        rm  ~/e2etest/util/*
        rmdir ~/e2etest/main
        rmdir ~/e2etest/util
        rmdir ~/e2etest
    fi
    if [ -f ~/.bashrc.bak ]; then
        rm ~/.bashrc.bak
        cp ~/.bashrc ~/.bashrc.bak
    fi
    sed -i "/# e2etest script/d" ~/.bashrc
    sed -i '/export PATH=$PATH:~\/e2etest\/main/d' ~/.bashrc
    sed -i "/source ~\/e2etest\/util\/autocomplete_e2etest.sh/d" ~/.bashrc
    echo "Info: Cleanup completed."
}


# Main uninstall function
uninstall_script() {
    echo "Info: Uninstaling script..."
    clean_up_installation
    echo "Info: Script required curl, jq, git and bash-completion installed."
    echo "Info: You can remove these packages manually if needed."
    echo "Info: Uninstall completed."
    exit 0
}

# Download and install updates
# $1 - remote version
install_updates() {
    # Check arg count and npe, assign values
    check_args 1 "$@"
    local remote_version=$1
    # Function logic
    update_url="https://github.com/$repo_owner/$repo_name/archive/refs/tags/v$remote_version.tar.gz"
    tmp_folder="tmp_e2etest_$remote_version"
    if [ -d "tmp_folder" ]; then
        rm -r "$tmp_folder"
    fi
    echo "Info: Downloading latest version..."
    wget -q -P "$tmp_folder" "$update_url"
    echo "Info: Download completed."
    echo "Info: Extracting..."
    cd "$tmp_folder"
    tar -xzf "v$remote_version.tar.gz"
    rm "v$remote_version.tar.gz"
    echo "Info: Extraction completed."
    cd "e2etest-$remote_version"
    ./e2etest.sh --install
    cd ../..
    rm -r "$tmp_folder"
}

# Generates autocomplete script in install folder
generate_autocomplete_script() {
    echo "Info: Generating 'autocomplete_e2etest.sh' script..."
    completion_text=$(cat <<EOL
#!/bin/bash

autocomplete_e2etest() {
    local cur prev words cword
    _init_completion || return

    local options="--version -v --chk-for-updates --auto-chk-for-updates-off --auto-chk-for-updates-on "
    options+="--help -h --install --install-y --uninstall "
    options+="--chk-install "
    options+="-t --token -s --scac -g --group -n --refnum --unit --acc-code --pronum --bolnum --ponum --pro --bol "
    options+="-c --config -q --quiet -a --all -r -x -o --rating --dispatch --tracking"

    if [[ "\${COMP_WORDS[*]}" =~ " --unit " ]]; then
        local unit_options=("true" "false")
        COMPREPLY=(\$(compgen -W "\${unit_options[*]}" -- "\${cur}"))
    else
        COMPREPLY=(\$(compgen -W "\$options" -- "\${cur}"))
    fi

    return 0
}

complete -F autocomplete_e2etest e2etest.sh
EOL
)
    echo "$completion_text" >> ~/e2etest/util/autocomplete_e2etest.sh
    chmod +x ~/e2etest/util/autocomplete_e2etest.sh
    echo "Info: Generated 'autocomplete_e2etest.sh' script."
}



# Check if there is a new release on e2etest GitHub repo
check_for_updates() {
    # Local script version
    local local_version=$(echo "$version" | sed 's/^v//')
    # Latest release text
    local latest_text=$(curl -s "https://api.github.com/repos/$repo_owner/$repo_name/releases/latest")
    # Latest remote version
    local remote_version=$(echo "$latest_text" | grep "tag_name" | sed 's/.*"v\([0-9.]*\)".*/\1/' | cat)
    # Check if versions are different
    local version_result=$(
        awk -v v1="$local_version" -v v2="$remote_version" '
            BEGIN {
                if (v1 == v2) {
                    result = 0;
                    exit;
                }
                split(v1, a, ".");
                split(v2, b, ".");
                for (i = 1; i <= length(a); i++) {
                    if (a[i] < b[i]) {
                        result = 1;
                        exit;
                    } else if (a[i] > b[i]) {
                        result = 2;
                        exit;
                    }
                }
                result = 0;
                exit;
            }
            END {
                print result
            }'
    )   
    if [ "$version_result" -eq 0 ]; then
        echo "Info: You already have the latest script version ($version)."
    elif [ "$version_result" -eq 1 ]; then
        local release_notes=$(echo "$latest_text" | grep "body" | sed -n 's/.*"body": "\([^"]*\)".*/\1/p' | sed 's/\\r\\n/\n/g' | cat)
        echo "Info: New version available (v$remote_version). Your version is (v$local_version)."
        echo "Info: Release notes:"
        echo "$release_notes"
        echo "Info: Visit '$repo/releases' for more info."
        echo "Q: Do you want to download and install updates? (Y/n):"
        read do_update
        if [ "${do_update,,}" == "y" ] || [ -z "$do_update" ]; then
            install_updates "$remote_version"
        else
            echo "Info: Update canceled."
        fi
    elif [ "$version_result" -eq 2 ]; then
        echo "Info: You somehow have a version that hasn't been released yet ;)"
        echo "Info: Latest release is (v$remote_version). Your version is (v$local_version)."
    fi
}



# Generates .env_e2etest file in current folder
generate_env_file() {
    echo "Info: Generating '.env_e2etest' file..."
    if [ -f "./.env_e2etest" ]; then
        rm ./.env_e2etest
    fi
    env_text=$(cat <<EOL
#!/bin/bash
# version="$version"
# author="$author"
# last_updated="$last_updated"
# github="$repo"

USE_QUIET_MODE=false
RUN_ALL=false
RUN_RATING=false
RUN_DISPATCH=false
RUN_TRACKING=false
GENERATE_OUTPUT=false
TOKEN=""
SCAC=""
ACCOUNT_GROUP="Default"
UNIT_SUPPORTED=false
ACC_CODE="INPU"
IDENTIFIER_TYPE="PRO"
PRO_NUM=""
BOL_NUM=""
PO_NUM=""
HELPER_DOC_FILE_NAME=helper_doc.txt

EOL
)
    echo "$env_text" >> ./.env_e2etest
    echo "Info: Generated '.env_e2etest' file."
}



###########################################################################################################################
############################################ Flags checks and function calls ##############################################
###########################################################################################################################



# If any args are passed, check if dependencies are installed
if [ "$flg_args_passed" == "true" ]; then
    check_dependencies
fi

# General option calls

# # Check for updates
if [ "$flg_chk_for_updates" == "true" ]; then
    check_for_updates
    # exit 0
fi

# Install
if [ "$do_install" == "true" ] || [ "$do_install_y" == "true" ]; then
    install_script
    exit 0
fi

# Uninstall
if [ "$do_uninstall" == "true" ]; then
    uninstall_script
    exit 0
fi

# Check installation
if [ "$do_chk_install" == "true" ]; then
    check_installation
    exit 0
fi

# Generate env file
if [ "$flg_generate_env_file" == "true" ]; then
    generate_env_file
    exit 0
fi


# Set up curl opts
curl_opts=""
status_code=""
# if [[ "$flg_use_quiet_mode" == true ]]; then
#     curl_opts="-s -o /dev/null -w \"%{http_code}\""
# fi

# Set up curl call scenario file prefix
curl_call_scenario_file_prefix="curl_call_scenario"

# Set up curl template
curl_opts=""

if [[ "$flg_use_quiet_mode" == "true" || "$flg_all" == "true" ]]; then
    curl_opts="-s -o /dev/null -w \"%{http_code}\""
fi


















# Start executing calls for services






# Start of: run rating
if [ "$flg_run_rating" == "true" ]; then

	# Set up logs
	logs_url="https://140271604703.observeinc.com/workspace/41124764/log-explorer?datasetId=41414971&time-preset=PAST_15_MINUTES&fv=41425674&s=21846-1oa7lvej"

	# Set up output folder
	if [ "$flg_generate_output" == "true" ]; then
		output_folder="curl_calls_${scac}_rating_$(date +'%Y-%m-%d_%H-%M-%S')"
		if [ -d "$output_folder" ]; then
			rm -r "$output_folder"
			mkdir "$output_folder"
		else
			mkdir "$output_folder"
		fi
	fi

	curl_template=$(cat <<-EOF
		curl $curl_opts --location 'https://na12.api.qa-integration.p-44.com/api/v4/ltl/quotes/rates/query' \
			--header "Authorization: Bearer $token" \
			--header "Content-Type: application/json" \
			--data
	EOF
	)

	

	scenario_number="01-1"
	scenario_name="Scenario $scenario_number"
	scenario_desc="(weight: 100 lbs, dimensions: 12x12x12)"
	if [[ ("$flg_all" == "true" || " ${scenarios_to_run[@]} " =~ " $scenario_number ") && ! " ${scenarios_to_exclude[@]} " =~ " $scenario_number " ]]; then
		# Scenario 01-1 (weight: 100 lbs, dimensions: 12x12x12)
		request_data=$(cat <<-EOF
			{
				"originAddress": {
					"postalCode": "60010",
					"addressLines": [],
					"city": "BARRINGTON $scenario_name",
					"state": "IL",
					"country": "US"
				},
				"destinationAddress": {
					"postalCode": "90210",
					"addressLines": [],
					"city": "BEVERLY HILLS $scenario_name",
					"state": "CA",
					"country": "US"
				},
				"lineItems": [
					{
						"totalWeight": "100",
						"packageDimensions": {
							"length": "12",
							"width": "12",
							"height": "12"
						},
						"packageType": "PLT",
						"totalPackages": 1,
						"totalPieces": 1,
						"freightClass": "50",
						"description": "$scenario_name"
					}
				],
				"capacityProviderAccountGroup": {
					"code": "$account_group",
					"accounts": [
						{
							"code": "$scac"
						}
					]
				},
				"accessorialServices": [],
				"pickupWindow": {
						"date": "$(date -d 'tomorrow' +'%Y-%m-%d')",
						"startTime": "$(date -d 'tomorrow' +'%H:%M')",
						"endTime": "$(date -d 'tomorrow 6 hours' +'%H:%M')"
				},
				"deliveryWindow":{
					"date": "$(date -d '2 days' +'%Y-%m-%d')",
					"startTime": "$(date -d '2 days 3 hours' +'%H:%M')",
					"endTime": "$(date -d '2 days 6 hours' +'%H:%M')"
				},
				"preferredCurrency": "USD",
				"totalLinearFeet": null,
				"linearFeetVisualizationIdentifier": null,
				"weightUnit": "LB",
				"lengthUnit": "IN",
				"apiConfiguration": {
					"enableUnitConversion": true,
					"accessorialServiceConfiguration": {
						"fetchAllServiceLevels": true,
						"allowUnacceptedAccessorials": false
					}
				}
			}
		EOF
		)

		curl_call=$(cat <<-EOF
			$curl_template '$request_data'
		EOF
		)
		if [ "$flg_generate_output" == "true" ]; then
			echo "$curl_call" > "$(pwd)/$output_folder/${curl_call_scenario_file_prefix}_$scenario_number.txt"
		fi
		response=$(eval "$curl_call" | jq)
		dash_count=$(($total_status_output_length - ${#scenario_name} - ${#scenario_desc} - 1))
		dashes=$(printf '%*s' "$dash_count" | tr ' ' '-')
		if [ "$flg_use_quiet_mode" == "false" ]; then
			echo -e "$scenario_name $scenario_desc response:\n$(echo "$response" | jq)"
		else
			echo "$scenario_name $scenario_desc $dashes Status code: $(print_status_code "$response")"
		fi
	fi


	scenario_number="01-2"
	scenario_name="Scenario $scenario_number"
	scenario_desc="(weight: 5000 lbs, dimensions: 96x48x48)"
	if [[ ("$flg_all" == "true" || " ${scenarios_to_run[@]} " =~ " $scenario_number ") && ! " ${scenarios_to_exclude[@]} " =~ " $scenario_number " ]]; then
		# Scenario 01-2 (weight: 5000 lbs, dimensions: 96x48x48)
		request_data=$(cat <<-EOF
			{
				"originAddress": {
					"postalCode": "60010",
					"addressLines": [],
					"city": "BARRINGTON $scenario_name",
					"state": "IL",
					"country": "US"
				},
				"destinationAddress": {
					"postalCode": "90210",
					"addressLines": [],
					"city": "BEVERLY HILLS $scenario_name",
					"state": "CA",
					"country": "US"
				},
				"lineItems": [
					{
						"totalWeight": "5000",
						"packageDimensions": {
							"length": "96",
							"width": "48",
							"height": "48"
						},
						"packageType": "PLT",
						"totalPackages": 1,
						"totalPieces": 1,
						"freightClass": "50",
						"description": "$scenario_name"
					}
				],
				"capacityProviderAccountGroup": {
					"code": "$account_group",
					"accounts": [
						{
							"code": "$scac"
						}
					]
				},
				"accessorialServices": [],
				"pickupWindow": {
						"date": "$(date -d 'tomorrow' +'%Y-%m-%d')",
						"startTime": "$(date -d 'tomorrow' +'%H:%M')",
						"endTime": "$(date -d 'tomorrow 6 hours' +'%H:%M')"
				},
				"deliveryWindow":{
					"date": "$(date -d '2 days' +'%Y-%m-%d')",
					"startTime": "$(date -d '2 days 3 hours' +'%H:%M')",
					"endTime": "$(date -d '2 days 6 hours' +'%H:%M')"
				},
				"preferredCurrency": "USD",
				"totalLinearFeet": null,
				"linearFeetVisualizationIdentifier": null,
				"weightUnit": "LB",
				"lengthUnit": "IN",
				"apiConfiguration": {
					"enableUnitConversion": true,
					"accessorialServiceConfiguration": {
						"fetchAllServiceLevels": true,
						"allowUnacceptedAccessorials": false
					}
				}
			}
		EOF
		)

		curl_call=$(cat <<-EOF
			$curl_template '$request_data'
		EOF
		)
		
		if [ "$flg_generate_output" == "true" ]; then
			echo "$curl_call" > "$(pwd)/$output_folder/${curl_call_scenario_file_prefix}_$scenario_number.txt"
		fi
		response=$(eval "$curl_call" | jq)
		dash_count=$(($total_status_output_length - ${#scenario_name} - ${#scenario_desc} - 1))
		dashes=$(printf '%*s' "$dash_count" | tr ' ' '-')
		if [ "$flg_use_quiet_mode" == "false" ]; then
			echo -e "$scenario_name $scenario_desc response:\n$(echo "$response" | jq)"
		else
			echo "$scenario_name $scenario_desc $dashes Status code: $(print_status_code "$response")"
		fi
	fi


	scenario_number="01-3"
	scenario_name="Scenario $scenario_number"
	scenario_desc="(weight: 0 lbs, dimensions: 0x0x0)"
	if [[ ("$flg_all" == "true" || " ${scenarios_to_run[@]} " =~ " $scenario_number ") && ! " ${scenarios_to_exclude[@]} " =~ " $scenario_number " ]]; then
		# Scenario 01-3 (weight: 0 lbs, dimensions: 0x0x0)
		request_data=$(cat <<-EOF
			{
				"originAddress": {
					"postalCode": "60010",
					"addressLines": [],
					"city": "BARRINGTON $scenario_name",
					"state": "IL",
					"country": "US"
				},
				"destinationAddress": {
					"postalCode": "90210",
					"addressLines": [],
					"city": "BEVERLY HILLS $scenario_name",
					"state": "CA",
					"country": "US"
				},
				"lineItems": [
					{
						"totalWeight": "0",
						"packageDimensions": {
							"length": "0",
							"width": "0",
							"height": "0"
						},
						"packageType": "PLT",
						"totalPackages": 1,
						"totalPieces": 1,
						"freightClass": "50",
						"description": "$scenario_name"
					}
				],
				"capacityProviderAccountGroup": {
					"code": "$account_group",
					"accounts": [
						{
							"code": "$scac"
						}
					]
				},
				"accessorialServices": [],
				"pickupWindow": {
						"date": "$(date -d 'tomorrow' +'%Y-%m-%d')",
						"startTime": "$(date -d 'tomorrow' +'%H:%M')",
						"endTime": "$(date -d 'tomorrow 6 hours' +'%H:%M')"
				},
				"deliveryWindow":{
					"date": "$(date -d '2 days' +'%Y-%m-%d')",
					"startTime": "$(date -d '2 days 3 hours' +'%H:%M')",
					"endTime": "$(date -d '2 days 6 hours' +'%H:%M')"
				},
				"preferredCurrency": "USD",
				"totalLinearFeet": null,
				"linearFeetVisualizationIdentifier": null,
				"weightUnit": "LB",
				"lengthUnit": "IN",
				"apiConfiguration": {
					"enableUnitConversion": true,
					"accessorialServiceConfiguration": {
						"fetchAllServiceLevels": true,
						"allowUnacceptedAccessorials": false
					}
				}
			}
		EOF
		)

		curl_call=$(cat <<-EOF
			$curl_template '$request_data'
		EOF
		)
		
		if [ "$flg_generate_output" == "true" ]; then
			echo "$curl_call" > "$(pwd)/$output_folder/${curl_call_scenario_file_prefix}_$scenario_number.txt"
		fi
		response=$(eval "$curl_call" | jq)
		dash_count=$(($total_status_output_length - ${#scenario_name} - ${#scenario_desc} - 1))
		dashes=$(printf '%*s' "$dash_count" | tr ' ' '-')
		if [ "$flg_use_quiet_mode" == "false" ]; then
			echo -e "$scenario_name $scenario_desc response:\n$(echo "$response" | jq)"
		else
			echo "$scenario_name $scenario_desc $dashes Status code: $(print_status_code "$response")"
		fi
	fi



	scenario_number="02-1"
	scenario_name="Scenario $scenario_number"
	scenario_desc="(dimensions: 10x10x10)"
	if [[ ("$flg_all" == "true" || " ${scenarios_to_run[@]} " =~ " $scenario_number ") && ! " ${scenarios_to_exclude[@]} " =~ " $scenario_number " ]]; then
		# Scenario 02-1 (dimensions: 10x10x10)		
		request_data=$(cat <<-EOF
			{
				"originAddress": {
					"postalCode": "60010",
					"addressLines": [],
					"city": "BARRINGTON $scenario_name",
					"state": "IL",
					"country": "US"
				},
				"destinationAddress": {
					"postalCode": "90210",
					"addressLines": [],
					"city": "BEVERLY HILLS $scenario_name",
					"state": "CA",
					"country": "US"
				},
				"lineItems": [
					{
						"totalWeight": "100",
						"packageDimensions": {
							"length": "10",
							"width": "10",
							"height": "10"
						},
						"packageType": "PLT",
						"totalPackages": 1,
						"totalPieces": 1,
						"freightClass": "50",
						"description": "$scenario_name"
					}
				],
				"capacityProviderAccountGroup": {
					"code": "$account_group",
					"accounts": [
						{
							"code": "$scac"
						}
					]
				},
				"accessorialServices": [],
				"pickupWindow": {
						"date": "$(date -d 'tomorrow' +'%Y-%m-%d')",
						"startTime": "$(date -d 'tomorrow' +'%H:%M')",
						"endTime": "$(date -d 'tomorrow 6 hours' +'%H:%M')"
				},
				"deliveryWindow":{
					"date": "$(date -d '2 days' +'%Y-%m-%d')",
					"startTime": "$(date -d '2 days 3 hours' +'%H:%M')",
					"endTime": "$(date -d '2 days 6 hours' +'%H:%M')"
				},
				"preferredCurrency": "USD",
				"totalLinearFeet": null,
				"linearFeetVisualizationIdentifier": null,
				"weightUnit": "LB",
				"lengthUnit": "IN",
				"apiConfiguration": {
					"enableUnitConversion": true,
					"accessorialServiceConfiguration": {
						"fetchAllServiceLevels": true,
						"allowUnacceptedAccessorials": false
					}
				}
			}
		EOF
		)

		curl_call=$(cat <<-EOF
			$curl_template '$request_data'
		EOF
		)

		if [ "$flg_generate_output" == "true" ]; then
			echo "$curl_call" > "$(pwd)/$output_folder/${curl_call_scenario_file_prefix}_$scenario_number.txt"
		fi
		response=$(eval "$curl_call" | jq)
		dash_count=$(($total_status_output_length - ${#scenario_name} - ${#scenario_desc} - 1))
		dashes=$(printf '%*s' "$dash_count" | tr ' ' '-')
		if [ "$flg_use_quiet_mode" == "false" ]; then
			echo -e "$scenario_name $scenario_desc response:\n$(echo "$response" | jq)"
		else
			echo "$scenario_name $scenario_desc $dashes Status code: $(print_status_code "$response")"
		fi
	fi


	scenario_number="02-2"
	scenario_name="Scenario $scenario_number"
	scenario_desc="(dimensions: 0x0x0)"
	if [[ ("$flg_all" == "true" || " ${scenarios_to_run[@]} " =~ " $scenario_number ") && ! " ${scenarios_to_exclude[@]} " =~ " $scenario_number " ]]; then
		# Scenario 02-2 (dimensions: 0x0x0)	
		request_data=$(cat <<-EOF
			{
				"originAddress": {
					"postalCode": "60010",
					"addressLines": [],
					"city": "BARRINGTON $scenario_name",
					"state": "IL",
					"country": "US"
				},
				"destinationAddress": {
					"postalCode": "90210",
					"addressLines": [],
					"city": "BEVERLY HILLS $scenario_name",
					"state": "CA",
					"country": "US"
				},
				"lineItems": [
					{
						"totalWeight": "100",
						"packageDimensions": {
							"length": "0",
							"width": "0",
							"height": "0"
						},
						"packageType": "PLT",
						"totalPackages": 1,
						"totalPieces": 1,
						"freightClass": "50",
						"description": "$scenario_name"
					}
				],
				"capacityProviderAccountGroup": {
					"code": "$account_group",
					"accounts": [
						{
							"code": "$scac"
						}
					]
				},
				"accessorialServices": [],
				"pickupWindow": {
						"date": "$(date -d 'tomorrow' +'%Y-%m-%d')",
						"startTime": "$(date -d 'tomorrow' +'%H:%M')",
						"endTime": "$(date -d 'tomorrow 6 hours' +'%H:%M')"
				},
				"deliveryWindow":{
					"date": "$(date -d '2 days' +'%Y-%m-%d')",
					"startTime": "$(date -d '2 days 3 hours' +'%H:%M')",
					"endTime": "$(date -d '2 days 6 hours' +'%H:%M')"
				},
				"preferredCurrency": "USD",
				"totalLinearFeet": null,
				"linearFeetVisualizationIdentifier": null,
				"weightUnit": "LB",
				"lengthUnit": "IN",
				"apiConfiguration": {
					"enableUnitConversion": true,
					"accessorialServiceConfiguration": {
						"fetchAllServiceLevels": true,
						"allowUnacceptedAccessorials": false
					}
				}
			}
		EOF
		)

		curl_call=$(cat <<-EOF
			$curl_template '$request_data'
		EOF
		)

		if [ "$flg_generate_output" == "true" ]; then
			echo "$curl_call" > "$(pwd)/$output_folder/${curl_call_scenario_file_prefix}_$scenario_number.txt"
		fi
		response=$(eval "$curl_call" | jq)
		dash_count=$(($total_status_output_length - ${#scenario_name} - ${#scenario_desc} - 1))
		dashes=$(printf '%*s' "$dash_count" | tr ' ' '-')
		if [ "$flg_use_quiet_mode" == "false" ]; then
			echo -e "$scenario_name $scenario_desc response:\n$(echo "$response" | jq)"
		else
			echo "$scenario_name $scenario_desc $dashes Status code: $(print_status_code "$response")"
		fi
	fi

	scenario_number="02-3"
	scenario_name="Scenario $scenario_number"
	scenario_desc="(dimensions: 500x500x500)"
	if [[ ("$flg_all" == "true" || " ${scenarios_to_run[@]} " =~ " $scenario_number ") && ! " ${scenarios_to_exclude[@]} " =~ " $scenario_number " ]]; then
		# Scenario 02-3 (dimensions: 500x500x500)		
		request_data=$(cat <<-EOF
			{
				"originAddress": {
					"postalCode": "60010",
					"addressLines": [],
					"city": "BARRINGTON $scenario_name",
					"state": "IL",
					"country": "US"
				},
				"destinationAddress": {
					"postalCode": "90210",
					"addressLines": [],
					"city": "BEVERLY HILLS $scenario_name",
					"state": "CA",
					"country": "US"
				},
				"lineItems": [
					{
						"totalWeight": "100",
						"packageDimensions": {
							"length": "500",
							"width": "500",
							"height": "500"
						},
						"packageType": "PLT",
						"totalPackages": 1,
						"totalPieces": 1,
						"freightClass": "50",
						"description": "$scenario_name"
					}
				],
				"capacityProviderAccountGroup": {
					"code": "$account_group",
					"accounts": [
						{
							"code": "$scac"
						}
					]
				},
				"accessorialServices": [],
				"pickupWindow": {
						"date": "$(date -d 'tomorrow' +'%Y-%m-%d')",
						"startTime": "$(date -d 'tomorrow' +'%H:%M')",
						"endTime": "$(date -d 'tomorrow 6 hours' +'%H:%M')"
				},
				"deliveryWindow":{
					"date": "$(date -d '2 days' +'%Y-%m-%d')",
					"startTime": "$(date -d '2 days 3 hours' +'%H:%M')",
					"endTime": "$(date -d '2 days 6 hours' +'%H:%M')"
				},
				"preferredCurrency": "USD",
				"totalLinearFeet": null,
				"linearFeetVisualizationIdentifier": null,
				"weightUnit": "LB",
				"lengthUnit": "IN",
				"apiConfiguration": {
					"enableUnitConversion": true,
					"accessorialServiceConfiguration": {
						"fetchAllServiceLevels": true,
						"allowUnacceptedAccessorials": false
					}
				}
			}
		EOF
		)

		curl_call=$(cat <<-EOF
			$curl_template '$request_data'
		EOF
		)

		if [ "$flg_generate_output" == "true" ]; then
			echo "$curl_call" > "$(pwd)/$output_folder/${curl_call_scenario_file_prefix}_$scenario_number.txt"
		fi
		response=$(eval "$curl_call" | jq)
		dash_count=$(($total_status_output_length - ${#scenario_name} - ${#scenario_desc} - 1))
		dashes=$(printf '%*s' "$dash_count" | tr ' ' '-')
		if [ "$flg_use_quiet_mode" == "false" ]; then
			echo -e "$scenario_name $scenario_desc response:\n$(echo "$response" | jq)"
		else
			echo "$scenario_name $scenario_desc $dashes Status code: $(print_status_code "$response")"
		fi
	fi


	scenario_number="02-4"
	scenario_name="Scenario $scenario_number"
	scenario_desc="(dimensions: null)"
	if [[ ("$flg_all" == "true" || " ${scenarios_to_run[@]} " =~ " $scenario_number ") && ! " ${scenarios_to_exclude[@]} " =~ " $scenario_number " ]]; then
		# Scenario 02-4 (dimensions: null)
		request_data=$(cat <<-EOF
			{
				"originAddress": {
					"postalCode": "60010",
					"addressLines": [],
					"city": "BARRINGTON $scenario_name",
					"state": "IL",
					"country": "US"
				},
				"destinationAddress": {
					"postalCode": "90210",
					"addressLines": [],
					"city": "BEVERLY HILLS $scenario_name",
					"state": "CA",
					"country": "US"
				},
				"lineItems": [
					{
						"totalWeight": "100",
						"packageDimensions": {
							"length": null,
							"width": null,
							"height": null
						},
						"packageType": "PLT",
						"totalPackages": 1,
						"totalPieces": 1,
						"freightClass": "50",
						"description": "$scenario_name"
					}
				],
				"capacityProviderAccountGroup": {
					"code": "$account_group",
					"accounts": [
						{
							"code": "$scac"
						}
					]
				},
				"accessorialServices": [],
				"pickupWindow": {
						"date": "$(date -d 'tomorrow' +'%Y-%m-%d')",
						"startTime": "$(date -d 'tomorrow' +'%H:%M')",
						"endTime": "$(date -d 'tomorrow 6 hours' +'%H:%M')"
				},
				"deliveryWindow":{
					"date": "$(date -d '2 days' +'%Y-%m-%d')",
					"startTime": "$(date -d '2 days 3 hours' +'%H:%M')",
					"endTime": "$(date -d '2 days 6 hours' +'%H:%M')"
				},
				"preferredCurrency": "USD",
				"totalLinearFeet": null,
				"linearFeetVisualizationIdentifier": null,
				"weightUnit": "LB",
				"lengthUnit": "IN",
				"apiConfiguration": {
					"enableUnitConversion": true,
					"accessorialServiceConfiguration": {
						"fetchAllServiceLevels": true,
						"allowUnacceptedAccessorials": false
					}
				}
			}
		EOF
		)

		curl_call=$(cat <<-EOF
			$curl_template '$request_data'
		EOF
		)

		if [ "$flg_generate_output" == "true" ]; then
			echo "$curl_call" > "$(pwd)/$output_folder/${curl_call_scenario_file_prefix}_$scenario_number.txt"
		fi
		response=$(eval "$curl_call" | jq)
		dash_count=$(($total_status_output_length - ${#scenario_name} - ${#scenario_desc} - 1))
		dashes=$(printf '%*s' "$dash_count" | tr ' ' '-')
		if [ "$flg_use_quiet_mode" == "false" ]; then
			echo -e "$scenario_name $scenario_desc response:\n$(echo "$response" | jq)"
		else
			echo "$scenario_name $scenario_desc $dashes Status code: $(print_status_code "$response")"
		fi
	fi

	scenario_number="03-1"
	scenario_name="Scenario $scenario_number"
	scenario_desc="(weight: 1000 lbs)"
	if [[ ("$flg_all" == "true" || " ${scenarios_to_run[@]} " =~ " $scenario_number ") && ! " ${scenarios_to_exclude[@]} " =~ " $scenario_number " ]]; then
		# Scenario 03-1 (weight: 1000 lbs)
		request_data=$(cat <<-EOF
			{
				"originAddress": {
					"postalCode": "60010",
					"addressLines": [],
					"city": "BARRINGTON $scenario_name",
					"state": "IL",
					"country": "US"
				},
				"destinationAddress": {
					"postalCode": "90210",
					"addressLines": [],
					"city": "BEVERLY HILLS $scenario_name",
					"state": "CA",
					"country": "US"
				},
				"lineItems": [
					{
						"totalWeight": "1000",
						"packageDimensions": {
							"length": "12",
							"width": "12",
							"height": "12"
						},
						"packageType": "PLT",
						"totalPackages": 1,
						"totalPieces": 1,
						"freightClass": "50",
						"description": "$scenario_name"
					}
				],
				"capacityProviderAccountGroup": {
					"code": "$account_group",
					"accounts": [
						{
							"code": "$scac"
						}
					]
				},
				"accessorialServices": [],
				"pickupWindow": {
						"date": "$(date -d 'tomorrow' +'%Y-%m-%d')",
						"startTime": "$(date -d 'tomorrow' +'%H:%M')",
						"endTime": "$(date -d 'tomorrow 6 hours' +'%H:%M')"
				},
				"deliveryWindow":{
					"date": "$(date -d '2 days' +'%Y-%m-%d')",
					"startTime": "$(date -d '2 days 3 hours' +'%H:%M')",
					"endTime": "$(date -d '2 days 6 hours' +'%H:%M')"
				},
				"preferredCurrency": "USD",
				"totalLinearFeet": null,
				"linearFeetVisualizationIdentifier": null,
				"weightUnit": "LB",
				"lengthUnit": "IN",
				"apiConfiguration": {
					"enableUnitConversion": true,
					"accessorialServiceConfiguration": {
						"fetchAllServiceLevels": true,
						"allowUnacceptedAccessorials": false
					}
				}
			}
		EOF
		)

		curl_call=$(cat <<-EOF
			$curl_template '$request_data'
		EOF
		)

		if [ "$flg_generate_output" == "true" ]; then
			echo "$curl_call" > "$(pwd)/$output_folder/${curl_call_scenario_file_prefix}_$scenario_number.txt"
		fi
		response=$(eval "$curl_call" | jq)
		dash_count=$(($total_status_output_length - ${#scenario_name} - ${#scenario_desc} - 1))
		dashes=$(printf '%*s' "$dash_count" | tr ' ' '-')
		if [ "$flg_use_quiet_mode" == "false" ]; then
			echo -e "$scenario_name $scenario_desc response:\n$(echo "$response" | jq)"
		else
			echo "$scenario_name $scenario_desc $dashes Status code: $(print_status_code "$response")"
		fi
	fi



	scenario_number="03-2"
	scenario_name="Scenario $scenario_number"
	scenario_desc="(weight: 0 lbs)"
	if [[ ("$flg_all" == "true" || " ${scenarios_to_run[@]} " =~ " $scenario_number ") && ! " ${scenarios_to_exclude[@]} " =~ " $scenario_number " ]]; then
		# Scenario 03-2 (weight: 0 lbs)
		request_data=$(cat <<-EOF
			{
				"originAddress": {
					"postalCode": "60010",
					"addressLines": [],
					"city": "BARRINGTON $scenario_name",
					"state": "IL",
					"country": "US"
				},
				"destinationAddress": {
					"postalCode": "90210",
					"addressLines": [],
					"city": "BEVERLY HILLS $scenario_name",
					"state": "CA",
					"country": "US"
				},
				"lineItems": [
					{
						"totalWeight": "0",
						"packageDimensions": {
							"length": "12",
							"width": "12",
							"height": "12"
						},
						"packageType": "PLT",
						"totalPackages": 1,
						"totalPieces": 1,
						"freightClass": "50",
						"description": "$scenario_name"
					}
				],
				"capacityProviderAccountGroup": {
					"code": "$account_group",
					"accounts": [
						{
							"code": "$scac"
						}
					]
				},
				"accessorialServices": [],
				"pickupWindow": {
						"date": "$(date -d 'tomorrow' +'%Y-%m-%d')",
						"startTime": "$(date -d 'tomorrow' +'%H:%M')",
						"endTime": "$(date -d 'tomorrow 6 hours' +'%H:%M')"
				},
				"deliveryWindow":{
					"date": "$(date -d '2 days' +'%Y-%m-%d')",
					"startTime": "$(date -d '2 days 3 hours' +'%H:%M')",
					"endTime": "$(date -d '2 days 6 hours' +'%H:%M')"
				},
				"preferredCurrency": "USD",
				"totalLinearFeet": null,
				"linearFeetVisualizationIdentifier": null,
				"weightUnit": "LB",
				"lengthUnit": "IN",
				"apiConfiguration": {
					"enableUnitConversion": true,
					"accessorialServiceConfiguration": {
						"fetchAllServiceLevels": true,
						"allowUnacceptedAccessorials": false
					}
				}
			}
		EOF
		)

		curl_call=$(cat <<-EOF
			$curl_template '$request_data'
		EOF
		)

		if [ "$flg_generate_output" == "true" ]; then
			echo "$curl_call" > "$(pwd)/$output_folder/${curl_call_scenario_file_prefix}_$scenario_number.txt"
		fi
		response=$(eval "$curl_call" | jq)
		dash_count=$(($total_status_output_length - ${#scenario_name} - ${#scenario_desc} - 1))
		dashes=$(printf '%*s' "$dash_count" | tr ' ' '-')
		if [ "$flg_use_quiet_mode" == "false" ]; then
			echo -e "$scenario_name $scenario_desc response:\n$(echo "$response" | jq)"
		else
			echo "$scenario_name $scenario_desc $dashes Status code: $(print_status_code "$response")"
		fi
	fi

	scenario_number="03-3"
	scenario_name="Scenario $scenario_number"
	scenario_desc="(weight: 5000 lbs)"
	if [[ ("$flg_all" == "true" || " ${scenarios_to_run[@]} " =~ " $scenario_number ") && ! " ${scenarios_to_exclude[@]} " =~ " $scenario_number " ]]; then
		# Scenario 03-3 (weight: 5000 lbs)
		request_data=$(cat <<-EOF
			{
				"originAddress": {
					"postalCode": "60010",
					"addressLines": [],
					"city": "BARRINGTON $scenario_name",
					"state": "IL",
					"country": "US"
				},
				"destinationAddress": {
					"postalCode": "90210",
					"addressLines": [],
					"city": "BEVERLY HILLS $scenario_name",
					"state": "CA",
					"country": "US"
				},
				"lineItems": [
					{
						"totalWeight": "5000",
						"packageDimensions": {
							"length": "12",
							"width": "12",
							"height": "12"
						},
						"packageType": "PLT",
						"totalPackages": 1,
						"totalPieces": 1,
						"freightClass": "50",
						"description": "$scenario_name"
					}
				],
				"capacityProviderAccountGroup": {
					"code": "$account_group",
					"accounts": [
						{
							"code": "$scac"
						}
					]
				},
				"accessorialServices": [],
				"pickupWindow": {
						"date": "$(date -d 'tomorrow' +'%Y-%m-%d')",
						"startTime": "$(date -d 'tomorrow' +'%H:%M')",
						"endTime": "$(date -d 'tomorrow 6 hours' +'%H:%M')"
				},
				"deliveryWindow":{
					"date": "$(date -d '2 days' +'%Y-%m-%d')",
					"startTime": "$(date -d '2 days 3 hours' +'%H:%M')",
					"endTime": "$(date -d '2 days 6 hours' +'%H:%M')"
				},
				"preferredCurrency": "USD",
				"totalLinearFeet": null,
				"linearFeetVisualizationIdentifier": null,
				"weightUnit": "LB",
				"lengthUnit": "IN",
				"apiConfiguration": {
					"enableUnitConversion": true,
					"accessorialServiceConfiguration": {
						"fetchAllServiceLevels": true,
						"allowUnacceptedAccessorials": false
					}
				}
			}
		EOF
		)

		curl_call=$(cat <<-EOF
			$curl_template '$request_data'
		EOF
		)

		if [ "$flg_generate_output" == "true" ]; then
			echo "$curl_call" > "$(pwd)/$output_folder/${curl_call_scenario_file_prefix}_$scenario_number.txt"
		fi
		response=$(eval "$curl_call" | jq)
		dash_count=$(($total_status_output_length - ${#scenario_name} - ${#scenario_desc} - 1))
		dashes=$(printf '%*s' "$dash_count" | tr ' ' '-')
		if [ "$flg_use_quiet_mode" == "false" ]; then
			echo -e "$scenario_name $scenario_desc response:\n$(echo "$response" | jq)"
		else
			echo "$scenario_name $scenario_desc $dashes Status code: $(print_status_code "$response")"
		fi
	fi


	scenario_number="03-4"
	scenario_name="Scenario $scenario_number"
	scenario_desc="(weight: null)"
	if [[ ("$flg_all" == "true" || " ${scenarios_to_run[@]} " =~ " $scenario_number ") && ! " ${scenarios_to_exclude[@]} " =~ " $scenario_number " ]]; then
		# Scenario 03-4 (weight: null)
		request_data=$(cat <<-EOF
			{
				"originAddress": {
					"postalCode": "60010",
					"addressLines": [],
					"city": "BARRINGTON $scenario_name",
					"state": "IL",
					"country": "US"
				},
				"destinationAddress": {
					"postalCode": "90210",
					"addressLines": [],
					"city": "BEVERLY HILLS $scenario_name",
					"state": "CA",
					"country": "US"
				},
				"lineItems": [
					{
						"totalWeight": null,
						"packageDimensions": {
							"length": "12",
							"width": "12",
							"height": "12"
						},
						"packageType": "PLT",
						"totalPackages": 1,
						"totalPieces": 1,
						"freightClass": "50",
						"description": "$scenario_name"
					}
				],
				"capacityProviderAccountGroup": {
					"code": "$account_group",
					"accounts": [
						{
							"code": "$scac"
						}
					]
				},
				"accessorialServices": [],
				"pickupWindow": {
						"date": "$(date -d 'tomorrow' +'%Y-%m-%d')",
						"startTime": "$(date -d 'tomorrow' +'%H:%M')",
						"endTime": "$(date -d 'tomorrow 6 hours' +'%H:%M')"
				},
				"deliveryWindow":{
					"date": "$(date -d '2 days' +'%Y-%m-%d')",
					"startTime": "$(date -d '2 days 3 hours' +'%H:%M')",
					"endTime": "$(date -d '2 days 6 hours' +'%H:%M')"
				},
				"preferredCurrency": "USD",
				"totalLinearFeet": null,
				"linearFeetVisualizationIdentifier": null,
				"weightUnit": "LB",
				"lengthUnit": "IN",
				"apiConfiguration": {
					"enableUnitConversion": true,
					"accessorialServiceConfiguration": {
						"fetchAllServiceLevels": true,
						"allowUnacceptedAccessorials": false
					}
				}
			}
		EOF
		)

		curl_call=$(cat <<-EOF
			$curl_template '$request_data'
		EOF
		)

		if [ "$flg_generate_output" == "true" ]; then
			echo "$curl_call" > "$(pwd)/$output_folder/${curl_call_scenario_file_prefix}_$scenario_number.txt"
		fi
		response=$(eval "$curl_call" | jq)
		dash_count=$(($total_status_output_length - ${#scenario_name} - ${#scenario_desc} - 1))
		dashes=$(printf '%*s' "$dash_count" | tr ' ' '-')
		if [ "$flg_use_quiet_mode" == "false" ]; then
			echo -e "$scenario_name $scenario_desc response:\n$(echo "$response" | jq)"
		else
			echo "$scenario_name $scenario_desc $dashes Status code: $(print_status_code "$response")"
		fi
	fi


	scenario_number="04-1"
	scenario_name="Scenario $scenario_number"
	scenario_desc="(2 pallets)"
	if [[ ("$flg_all" == "true" || " ${scenarios_to_run[@]} " =~ " $scenario_number ") && ! " ${scenarios_to_exclude[@]} " =~ " $scenario_number " ]]; then
		# Scenario 04-1 (2 pallets)
		request_data=$(cat <<-EOF
			{
				"originAddress": {
					"postalCode": "60010",
					"addressLines": [],
					"city": "BARRINGTON $scenario_name",
					"state": "IL",
					"country": "US"
				},
				"destinationAddress": {
					"postalCode": "90210",
					"addressLines": [],
					"city": "BEVERLY HILLS $scenario_name",
					"state": "CA",
					"country": "US"
				},
				"lineItems": [
					{
						"totalWeight": "100",
						"packageDimensions": {
							"length": "12",
							"width": "12",
							"height": "12"
						},
						"packageType": "PLT",
						"totalPackages": 2,
						"totalPieces": 1,
						"freightClass": "50",
						"description": "$scenario_name"
					}
				],
				"capacityProviderAccountGroup": {
					"code": "$account_group",
					"accounts": [
						{
							"code": "$scac"
						}
					]
				},
				"accessorialServices": [],
				"pickupWindow": {
						"date": "$(date -d 'tomorrow' +'%Y-%m-%d')",
						"startTime": "$(date -d 'tomorrow' +'%H:%M')",
						"endTime": "$(date -d 'tomorrow 6 hours' +'%H:%M')"
				},
				"deliveryWindow":{
					"date": "$(date -d '2 days' +'%Y-%m-%d')",
					"startTime": "$(date -d '2 days 3 hours' +'%H:%M')",
					"endTime": "$(date -d '2 days 6 hours' +'%H:%M')"
				},
				"preferredCurrency": "USD",
				"totalLinearFeet": null,
				"linearFeetVisualizationIdentifier": null,
				"weightUnit": "LB",
				"lengthUnit": "IN",
				"apiConfiguration": {
					"enableUnitConversion": true,
					"accessorialServiceConfiguration": {
						"fetchAllServiceLevels": true,
						"allowUnacceptedAccessorials": false
					}
				}
			}
		EOF
		)

		curl_call=$(cat <<-EOF
			$curl_template '$request_data'
		EOF
		)
		
		if [ "$flg_generate_output" == "true" ]; then
			echo "$curl_call" > "$(pwd)/$output_folder/${curl_call_scenario_file_prefix}_$scenario_number.txt"
		fi
		response=$(eval "$curl_call" | jq)
		dash_count=$(($total_status_output_length - ${#scenario_name} - ${#scenario_desc} - 1))
		dashes=$(printf '%*s' "$dash_count" | tr ' ' '-')
		if [ "$flg_use_quiet_mode" == "false" ]; then
			echo -e "$scenario_name $scenario_desc response:\n$(echo "$response" | jq)"
		else
			echo "$scenario_name $scenario_desc $dashes Status code: $(print_status_code "$response")"
		fi
	fi


	scenario_number="04-2"
	scenario_name="Scenario $scenario_number"
	scenario_desc="(3 cartons)"
	if [[ ("$flg_all" == "true" || " ${scenarios_to_run[@]} " =~ " $scenario_number ") && ! " ${scenarios_to_exclude[@]} " =~ " $scenario_number " ]]; then
		# Scenario 04-2 (3 cartons)
		request_data=$(cat <<-EOF
			{
				"originAddress": {
					"postalCode": "60010",
					"addressLines": [],
					"city": "BARRINGTON $scenario_name",
					"state": "IL",
					"country": "US"
				},
				"destinationAddress": {
					"postalCode": "90210",
					"addressLines": [],
					"city": "BEVERLY HILLS $scenario_name",
					"state": "CA",
					"country": "US"
				},
				"lineItems": [
					{
						"totalWeight": "100",
						"packageDimensions": {
							"length": "12",
							"width": "12",
							"height": "12"
						},
						"packageType": "CARTON",
						"totalPackages": 3,
						"totalPieces": 1,
						"freightClass": "50",
						"description": "$scenario_name"
					}
				],
				"capacityProviderAccountGroup": {
					"code": "$account_group",
					"accounts": [
						{
							"code": "$scac"
						}
					]
				},
				"accessorialServices": [],
				"pickupWindow": {
						"date": "$(date -d 'tomorrow' +'%Y-%m-%d')",
						"startTime": "$(date -d 'tomorrow' +'%H:%M')",
						"endTime": "$(date -d 'tomorrow 6 hours' +'%H:%M')"
				},
				"deliveryWindow":{
					"date": "$(date -d '2 days' +'%Y-%m-%d')",
					"startTime": "$(date -d '2 days 3 hours' +'%H:%M')",
					"endTime": "$(date -d '2 days 6 hours' +'%H:%M')"
				},
				"preferredCurrency": "USD",
				"totalLinearFeet": null,
				"linearFeetVisualizationIdentifier": null,
				"weightUnit": "LB",
				"lengthUnit": "IN",
				"apiConfiguration": {
					"enableUnitConversion": true,
					"accessorialServiceConfiguration": {
						"fetchAllServiceLevels": true,
						"allowUnacceptedAccessorials": false
					}
				}
			}
		EOF
		)

		curl_call=$(cat <<-EOF
			$curl_template '$request_data'
		EOF
		)
		
		if [ "$flg_generate_output" == "true" ]; then
			echo "$curl_call" > "$(pwd)/$output_folder/${curl_call_scenario_file_prefix}_$scenario_number.txt"
		fi
		response=$(eval "$curl_call" | jq)
		dash_count=$(($total_status_output_length - ${#scenario_name} - ${#scenario_desc} - 1))
		dashes=$(printf '%*s' "$dash_count" | tr ' ' '-')
		if [ "$flg_use_quiet_mode" == "false" ]; then
			echo -e "$scenario_name $scenario_desc response:\n$(echo "$response" | jq)"
		else
			echo "$scenario_name $scenario_desc $dashes Status code: $(print_status_code "$response")"
		fi
	fi



	scenario_number="04-3"
	scenario_name="Scenario $scenario_number"
	scenario_desc="(1 skid)"
	if [[ ("$flg_all" == "true" || " ${scenarios_to_run[@]} " =~ " $scenario_number ") && ! " ${scenarios_to_exclude[@]} " =~ " $scenario_number " ]]; then
		# Scenario 04-3 (1 skid)
		request_data=$(cat <<-EOF
			{
				"originAddress": {
					"postalCode": "60010",
					"addressLines": [],
					"city": "BARRINGTON $scenario_name",
					"state": "IL",
					"country": "US"
				},
				"destinationAddress": {
					"postalCode": "90210",
					"addressLines": [],
					"city": "BEVERLY HILLS $scenario_name",
					"state": "CA",
					"country": "US"
				},
				"lineItems": [
					{
						"totalWeight": "100",
						"packageDimensions": {
							"length": "12",
							"width": "12",
							"height": "12"
						},
						"packageType": "PLT",
						"totalPackages": 2,
						"totalPieces": 1,
						"freightClass": "50",
						"description": "$scenario_name"
					}
				],
				"capacityProviderAccountGroup": {
					"code": "$account_group",
					"accounts": [
						{
							"code": "$scac"
						}
					]
				},
				"accessorialServices": [],
				"pickupWindow": {
						"date": "$(date -d 'tomorrow' +'%Y-%m-%d')",
						"startTime": "$(date -d 'tomorrow' +'%H:%M')",
						"endTime": "$(date -d 'tomorrow 6 hours' +'%H:%M')"
				},
				"deliveryWindow":{
					"date": "$(date -d '2 days' +'%Y-%m-%d')",
					"startTime": "$(date -d '2 days 3 hours' +'%H:%M')",
					"endTime": "$(date -d '2 days 6 hours' +'%H:%M')"
				},
				"preferredCurrency": "USD",
				"totalLinearFeet": null,
				"linearFeetVisualizationIdentifier": null,
				"weightUnit": "LB",
				"lengthUnit": "IN",
				"apiConfiguration": {
					"enableUnitConversion": true,
					"accessorialServiceConfiguration": {
						"fetchAllServiceLevels": true,
						"allowUnacceptedAccessorials": false
					}
				}
			}
		EOF
		)

		curl_call=$(cat <<-EOF
			$curl_template '$request_data'
		EOF
		)
		
		if [ "$flg_generate_output" == "true" ]; then
			echo "$curl_call" > "$(pwd)/$output_folder/${curl_call_scenario_file_prefix}_$scenario_number.txt"
		fi
		response=$(eval "$curl_call" | jq)
		dash_count=$(($total_status_output_length - ${#scenario_name} - ${#scenario_desc} - 1))
		dashes=$(printf '%*s' "$dash_count" | tr ' ' '-')
		if [ "$flg_use_quiet_mode" == "false" ]; then
			echo -e "$scenario_name $scenario_desc response:\n$(echo "$response" | jq)"
		else
			echo "$scenario_name $scenario_desc $dashes Status code: $(print_status_code "$response")"
		fi
	fi


	scenario_number="05-1"
	scenario_name="Scenario $scenario_number"
	scenario_desc="(1 package)"
	if [[ ("$flg_all" == "true" || " ${scenarios_to_run[@]} " =~ " $scenario_number ") && ! " ${scenarios_to_exclude[@]} " =~ " $scenario_number " ]]; then
		# Scenario 05-1 (1 package)
		request_data=$(cat <<-EOF
			{
				"originAddress": {
					"postalCode": "60010",
					"addressLines": [],
					"city": "BARRINGTON $scenario_name",
					"state": "IL",
					"country": "US"
				},
				"destinationAddress": {
					"postalCode": "90210",
					"addressLines": [],
					"city": "BEVERLY HILLS $scenario_name",
					"state": "CA",
					"country": "US"
				},
				"lineItems": [
					{
						"totalWeight": "100",
						"packageDimensions": {
							"length": "12",
							"width": "12",
							"height": "12"
						},
						"packageType": "PLT",
						"totalPackages": 1,
						"totalPieces": 1,
						"freightClass": "50",
						"description": "$scenario_name"
					}
				],
				"capacityProviderAccountGroup": {
					"code": "$account_group",
					"accounts": [
						{
							"code": "$scac"
						}
					]
				},
				"accessorialServices": [],
				"pickupWindow": {
						"date": "$(date -d 'tomorrow' +'%Y-%m-%d')",
						"startTime": "$(date -d 'tomorrow' +'%H:%M')",
						"endTime": "$(date -d 'tomorrow 6 hours' +'%H:%M')"
				},
				"deliveryWindow":{
					"date": "$(date -d '2 days' +'%Y-%m-%d')",
					"startTime": "$(date -d '2 days 3 hours' +'%H:%M')",
					"endTime": "$(date -d '2 days 6 hours' +'%H:%M')"
				},
				"preferredCurrency": "USD",
				"totalLinearFeet": null,
				"linearFeetVisualizationIdentifier": null,
				"weightUnit": "LB",
				"lengthUnit": "IN",
				"apiConfiguration": {
					"enableUnitConversion": true,
					"accessorialServiceConfiguration": {
						"fetchAllServiceLevels": true,
						"allowUnacceptedAccessorials": false
					}
				}
			}
		EOF
		)

		curl_call=$(cat <<-EOF
			$curl_template '$request_data'
		EOF
		)
		
		if [ "$flg_generate_output" == "true" ]; then
			echo "$curl_call" > "$(pwd)/$output_folder/${curl_call_scenario_file_prefix}_$scenario_number.txt"
		fi
		response=$(eval "$curl_call" | jq)
		dash_count=$(($total_status_output_length - ${#scenario_name} - ${#scenario_desc} - 1))
		dashes=$(printf '%*s' "$dash_count" | tr ' ' '-')
		if [ "$flg_use_quiet_mode" == "false" ]; then
			echo -e "$scenario_name $scenario_desc response:\n$(echo "$response" | jq)"
		else
			echo "$scenario_name $scenario_desc $dashes Status code: $(print_status_code "$response")"
		fi
	fi



	scenario_number="05-2"
	scenario_name="Scenario $scenario_number"
	scenario_desc="(5 packages)"
	if [[ ("$flg_all" == "true" || " ${scenarios_to_run[@]} " =~ " $scenario_number ") && ! " ${scenarios_to_exclude[@]} " =~ " $scenario_number " ]]; then
		# Scenario 05-2 (5 packages)
		request_data=$(cat <<-EOF
			{
				"originAddress": {
					"postalCode": "60010",
					"addressLines": [],
					"city": "BARRINGTON $scenario_name",
					"state": "IL",
					"country": "US"
				},
				"destinationAddress": {
					"postalCode": "90210",
					"addressLines": [],
					"city": "BEVERLY HILLS $scenario_name",
					"state": "CA",
					"country": "US"
				},
				"lineItems": [
					{
						"totalWeight": "100",
						"packageDimensions": {
							"length": "12",
							"width": "12",
							"height": "12"
						},
						"packageType": "PLT",
						"totalPackages": 5,
						"totalPieces": 1,
						"freightClass": "50",
						"description": "$scenario_name"
					}
				],
				"capacityProviderAccountGroup": {
					"code": "$account_group",
					"accounts": [
						{
							"code": "$scac"
						}
					]
				},
				"accessorialServices": [],
				"pickupWindow": {
						"date": "$(date -d 'tomorrow' +'%Y-%m-%d')",
						"startTime": "$(date -d 'tomorrow' +'%H:%M')",
						"endTime": "$(date -d 'tomorrow 6 hours' +'%H:%M')"
				},
				"deliveryWindow":{
					"date": "$(date -d '2 days' +'%Y-%m-%d')",
					"startTime": "$(date -d '2 days 3 hours' +'%H:%M')",
					"endTime": "$(date -d '2 days 6 hours' +'%H:%M')"
				},
				"preferredCurrency": "USD",
				"totalLinearFeet": null,
				"linearFeetVisualizationIdentifier": null,
				"weightUnit": "LB",
				"lengthUnit": "IN",
				"apiConfiguration": {
					"enableUnitConversion": true,
					"accessorialServiceConfiguration": {
						"fetchAllServiceLevels": true,
						"allowUnacceptedAccessorials": false
					}
				}
			}
		EOF
		)

		curl_call=$(cat <<-EOF
			$curl_template '$request_data'
		EOF
		)
		
		if [ "$flg_generate_output" == "true" ]; then
			echo "$curl_call" > "$(pwd)/$output_folder/${curl_call_scenario_file_prefix}_$scenario_number.txt"
		fi
		response=$(eval "$curl_call" | jq)
		dash_count=$(($total_status_output_length - ${#scenario_name} - ${#scenario_desc} - 1))
		dashes=$(printf '%*s' "$dash_count" | tr ' ' '-')
		if [ "$flg_use_quiet_mode" == "false" ]; then
			echo -e "$scenario_name $scenario_desc response:\n$(echo "$response" | jq)"
		else
			echo "$scenario_name $scenario_desc $dashes Status code: $(print_status_code "$response")"
		fi
	fi


	scenario_number="05-3"
	scenario_name="Scenario $scenario_number"
	scenario_desc="(10 packages)"
	if [[ ("$flg_all" == "true" || " ${scenarios_to_run[@]} " =~ " $scenario_number ") && ! " ${scenarios_to_exclude[@]} " =~ " $scenario_number " ]]; then
		# Scenario 05-3 (10 packages)
		request_data=$(cat <<-EOF
			{
				"originAddress": {
					"postalCode": "60010",
					"addressLines": [],
					"city": "BARRINGTON $scenario_name",
					"state": "IL",
					"country": "US"
				},
				"destinationAddress": {
					"postalCode": "90210",
					"addressLines": [],
					"city": "BEVERLY HILLS $scenario_name",
					"state": "CA",
					"country": "US"
				},
				"lineItems": [
					{
						"totalWeight": "100",
						"packageDimensions": {
							"length": "12",
							"width": "12",
							"height": "12"
						},
						"packageType": "PLT",
						"totalPackages": 10,
						"totalPieces": 1,
						"freightClass": "50",
						"description": "$scenario_name"
					}
				],
				"capacityProviderAccountGroup": {
					"code": "$account_group",
					"accounts": [
						{
							"code": "$scac"
						}
					]
				},
				"accessorialServices": [],
				"pickupWindow": {
						"date": "$(date -d 'tomorrow' +'%Y-%m-%d')",
						"startTime": "$(date -d 'tomorrow' +'%H:%M')",
						"endTime": "$(date -d 'tomorrow 6 hours' +'%H:%M')"
				},
				"deliveryWindow":{
					"date": "$(date -d '2 days' +'%Y-%m-%d')",
					"startTime": "$(date -d '2 days 3 hours' +'%H:%M')",
					"endTime": "$(date -d '2 days 6 hours' +'%H:%M')"
				},
				"preferredCurrency": "USD",
				"totalLinearFeet": null,
				"linearFeetVisualizationIdentifier": null,
				"weightUnit": "LB",
				"lengthUnit": "IN",
				"apiConfiguration": {
					"enableUnitConversion": true,
					"accessorialServiceConfiguration": {
						"fetchAllServiceLevels": true,
						"allowUnacceptedAccessorials": false
					}
				}
			}
		EOF
		)

		curl_call=$(cat <<-EOF
			$curl_template '$request_data'
		EOF
		)
		
		if [ "$flg_generate_output" == "true" ]; then
			echo "$curl_call" > "$(pwd)/$output_folder/${curl_call_scenario_file_prefix}_$scenario_number.txt"
		fi
		response=$(eval "$curl_call" | jq)
		dash_count=$(($total_status_output_length - ${#scenario_name} - ${#scenario_desc} - 1))
		dashes=$(printf '%*s' "$dash_count" | tr ' ' '-')
		if [ "$flg_use_quiet_mode" == "false" ]; then
			echo -e "$scenario_name $scenario_desc response:\n$(echo "$response" | jq)"
		else
			echo "$scenario_name $scenario_desc $dashes Status code: $(print_status_code "$response")"
		fi
	fi





	scenario_number="06-1"
	scenario_name="Scenario $scenario_number"
	scenario_desc="(package type: BAG)"
	if [[ ("$flg_all" == "true" || " ${scenarios_to_run[@]} " =~ " $scenario_number ") && ! " ${scenarios_to_exclude[@]} " =~ " $scenario_number " ]]; then
		# Scenario 06-1 (package type: BAG)
		request_data=$(cat <<-EOF
			{
				"originAddress": {
					"postalCode": "60010",
					"addressLines": [],
					"city": "BARRINGTON $scenario_name",
					"state": "IL",
					"country": "US"
				},
				"destinationAddress": {
					"postalCode": "90210",
					"addressLines": [],
					"city": "BEVERLY HILLS $scenario_name",
					"state": "CA",
					"country": "US"
				},
				"lineItems": [
					{
						"totalWeight": "100",
						"packageDimensions": {
							"length": "12",
							"width": "12",
							"height": "12"
						},
						"packageType": "BAG",
						"totalPackages": 1,
						"totalPieces": 1,
						"freightClass": "50",
						"description": "$scenario_name"
					}
				],
				"capacityProviderAccountGroup": {
					"code": "$account_group",
					"accounts": [
						{
							"code": "$scac"
						}
					]
				},
				"accessorialServices": [],
				"pickupWindow": {
						"date": "$(date -d 'tomorrow' +'%Y-%m-%d')",
						"startTime": "$(date -d 'tomorrow' +'%H:%M')",
						"endTime": "$(date -d 'tomorrow 6 hours' +'%H:%M')"
				},
				"deliveryWindow":{
					"date": "$(date -d '2 days' +'%Y-%m-%d')",
					"startTime": "$(date -d '2 days 3 hours' +'%H:%M')",
					"endTime": "$(date -d '2 days 6 hours' +'%H:%M')"
				},
				"preferredCurrency": "USD",
				"totalLinearFeet": null,
				"linearFeetVisualizationIdentifier": null,
				"weightUnit": "LB",
				"lengthUnit": "IN",
				"apiConfiguration": {
					"enableUnitConversion": true,
					"accessorialServiceConfiguration": {
						"fetchAllServiceLevels": true,
						"allowUnacceptedAccessorials": false
					}
				}
			}
		EOF
		)

		curl_call=$(cat <<-EOF
			$curl_template '$request_data'
		EOF
		)
		
		if [ "$flg_generate_output" == "true" ]; then
			echo "$curl_call" > "$(pwd)/$output_folder/${curl_call_scenario_file_prefix}_$scenario_number.txt"
		fi
		response=$(eval "$curl_call" | jq)
		dash_count=$(($total_status_output_length - ${#scenario_name} - ${#scenario_desc} - 1))
		dashes=$(printf '%*s' "$dash_count" | tr ' ' '-')
		if [ "$flg_use_quiet_mode" == "false" ]; then
			echo -e "$scenario_name $scenario_desc response:\n$(echo "$response" | jq)"
		else
			echo "$scenario_name $scenario_desc $dashes Status code: $(print_status_code "$response")"
		fi
	fi




	scenario_number="06-2"
	scenario_name="Scenario $scenario_number"
	scenario_desc="(package type: BOX)"
	if [[ ("$flg_all" == "true" || " ${scenarios_to_run[@]} " =~ " $scenario_number ") && ! " ${scenarios_to_exclude[@]} " =~ " $scenario_number " ]]; then
		# Scenario 06-2 (package type: BOX)
		request_data=$(cat <<-EOF
			{
				"originAddress": {
					"postalCode": "60010",
					"addressLines": [],
					"city": "BARRINGTON $scenario_name",
					"state": "IL",
					"country": "US"
				},
				"destinationAddress": {
					"postalCode": "90210",
					"addressLines": [],
					"city": "BEVERLY HILLS $scenario_name",
					"state": "CA",
					"country": "US"
				},
				"lineItems": [
					{
						"totalWeight": "100",
						"packageDimensions": {
							"length": "12",
							"width": "12",
							"height": "12"
						},
						"packageType": "BOX",
						"totalPackages": 1,
						"totalPieces": 1,
						"freightClass": "50",
						"description": "$scenario_name"
					}
				],
				"capacityProviderAccountGroup": {
					"code": "$account_group",
					"accounts": [
						{
							"code": "$scac"
						}
					]
				},
				"accessorialServices": [],
				"pickupWindow": {
						"date": "$(date -d 'tomorrow' +'%Y-%m-%d')",
						"startTime": "$(date -d 'tomorrow' +'%H:%M')",
						"endTime": "$(date -d 'tomorrow 6 hours' +'%H:%M')"
				},
				"deliveryWindow":{
					"date": "$(date -d '2 days' +'%Y-%m-%d')",
					"startTime": "$(date -d '2 days 3 hours' +'%H:%M')",
					"endTime": "$(date -d '2 days 6 hours' +'%H:%M')"
				},
				"preferredCurrency": "USD",
				"totalLinearFeet": null,
				"linearFeetVisualizationIdentifier": null,
				"weightUnit": "LB",
				"lengthUnit": "IN",
				"apiConfiguration": {
					"enableUnitConversion": true,
					"accessorialServiceConfiguration": {
						"fetchAllServiceLevels": true,
						"allowUnacceptedAccessorials": false
					}
				}
			}
		EOF
		)

		curl_call=$(cat <<-EOF
			$curl_template '$request_data'
		EOF
		)
		
		if [ "$flg_generate_output" == "true" ]; then
			echo "$curl_call" > "$(pwd)/$output_folder/${curl_call_scenario_file_prefix}_$scenario_number.txt"
		fi
		response=$(eval "$curl_call" | jq)
		dash_count=$(($total_status_output_length - ${#scenario_name} - ${#scenario_desc} - 1))
		dashes=$(printf '%*s' "$dash_count" | tr ' ' '-')
		if [ "$flg_use_quiet_mode" == "false" ]; then
			echo -e "$scenario_name $scenario_desc response:\n$(echo "$response" | jq)"
		else
			echo "$scenario_name $scenario_desc $dashes Status code: $(print_status_code "$response")"
		fi
	fi




	scenario_number="06-3"
	scenario_name="Scenario $scenario_number"
	scenario_desc="(package type: SKID)"
	if [[ ("$flg_all" == "true" || " ${scenarios_to_run[@]} " =~ " $scenario_number ") && ! " ${scenarios_to_exclude[@]} " =~ " $scenario_number " ]]; then
		# Scenario 06-3 (package type: SKID)
		request_data=$(cat <<-EOF
			{
				"originAddress": {
					"postalCode": "60010",
					"addressLines": [],
					"city": "BARRINGTON $scenario_name",
					"state": "IL",
					"country": "US"
				},
				"destinationAddress": {
					"postalCode": "90210",
					"addressLines": [],
					"city": "BEVERLY HILLS $scenario_name",
					"state": "CA",
					"country": "US"
				},
				"lineItems": [
					{
						"totalWeight": "100",
						"packageDimensions": {
							"length": "12",
							"width": "12",
							"height": "12"
						},
						"packageType": "SKID",
						"totalPackages": 1,
						"totalPieces": 1,
						"freightClass": "50",
						"description": "$scenario_name"
					}
				],
				"capacityProviderAccountGroup": {
					"code": "$account_group",
					"accounts": [
						{
							"code": "$scac"
						}
					]
				},
				"accessorialServices": [],
				"pickupWindow": {
						"date": "$(date -d 'tomorrow' +'%Y-%m-%d')",
						"startTime": "$(date -d 'tomorrow' +'%H:%M')",
						"endTime": "$(date -d 'tomorrow 6 hours' +'%H:%M')"
				},
				"deliveryWindow":{
					"date": "$(date -d '2 days' +'%Y-%m-%d')",
					"startTime": "$(date -d '2 days 3 hours' +'%H:%M')",
					"endTime": "$(date -d '2 days 6 hours' +'%H:%M')"
				},
				"preferredCurrency": "USD",
				"totalLinearFeet": null,
				"linearFeetVisualizationIdentifier": null,
				"weightUnit": "LB",
				"lengthUnit": "IN",
				"apiConfiguration": {
					"enableUnitConversion": true,
					"accessorialServiceConfiguration": {
						"fetchAllServiceLevels": true,
						"allowUnacceptedAccessorials": false
					}
				}
			}
		EOF
		)

		curl_call=$(cat <<-EOF
			$curl_template '$request_data'
		EOF
		)
		
		if [ "$flg_generate_output" == "true" ]; then
			echo "$curl_call" > "$(pwd)/$output_folder/${curl_call_scenario_file_prefix}_$scenario_number.txt"
		fi
		response=$(eval "$curl_call" | jq)
		dash_count=$(($total_status_output_length - ${#scenario_name} - ${#scenario_desc} - 1))
		dashes=$(printf '%*s' "$dash_count" | tr ' ' '-')
		if [ "$flg_use_quiet_mode" == "false" ]; then
			echo -e "$scenario_name $scenario_desc response:\n$(echo "$response" | jq)"
		else
			echo "$scenario_name $scenario_desc $dashes Status code: $(print_status_code "$response")"
		fi
	fi





	scenario_number="06-4"
	scenario_name="Scenario $scenario_number"
	scenario_desc="(package type: null)"
	if [[ ("$flg_all" == "true" || " ${scenarios_to_run[@]} " =~ " $scenario_number ") && ! " ${scenarios_to_exclude[@]} " =~ " $scenario_number " ]]; then
		# Scenario 06-4 (package type: null)
		request_data=$(cat <<-EOF
			{
				"originAddress": {
					"postalCode": "60010",
					"addressLines": [],
					"city": "BARRINGTON $scenario_name",
					"state": "IL",
					"country": "US"
				},
				"destinationAddress": {
					"postalCode": "90210",
					"addressLines": [],
					"city": "BEVERLY HILLS $scenario_name",
					"state": "CA",
					"country": "US"
				},
				"lineItems": [
					{
						"totalWeight": "100",
						"packageDimensions": {
							"length": "12",
							"width": "12",
							"height": "12"
						},
						"packageType": null,
						"totalPackages": 1,
						"totalPieces": 1,
						"freightClass": "50",
						"description": "$scenario_name"
					}
				],
				"capacityProviderAccountGroup": {
					"code": "$account_group",
					"accounts": [
						{
							"code": "$scac"
						}
					]
				},
				"accessorialServices": [],
				"pickupWindow": {
						"date": "$(date -d 'tomorrow' +'%Y-%m-%d')",
						"startTime": "$(date -d 'tomorrow' +'%H:%M')",
						"endTime": "$(date -d 'tomorrow 6 hours' +'%H:%M')"
				},
				"deliveryWindow":{
					"date": "$(date -d '2 days' +'%Y-%m-%d')",
					"startTime": "$(date -d '2 days 3 hours' +'%H:%M')",
					"endTime": "$(date -d '2 days 6 hours' +'%H:%M')"
				},
				"preferredCurrency": "USD",
				"totalLinearFeet": null,
				"linearFeetVisualizationIdentifier": null,
				"weightUnit": "LB",
				"lengthUnit": "IN",
				"apiConfiguration": {
					"enableUnitConversion": true,
					"accessorialServiceConfiguration": {
						"fetchAllServiceLevels": true,
						"allowUnacceptedAccessorials": false
					}
				}
			}
		EOF
		)

		curl_call=$(cat <<-EOF
			$curl_template '$request_data'
		EOF
		)
		
		if [ "$flg_generate_output" == "true" ]; then
			echo "$curl_call" > "$(pwd)/$output_folder/${curl_call_scenario_file_prefix}_$scenario_number.txt"
		fi
		response=$(eval "$curl_call" | jq)
		dash_count=$(($total_status_output_length - ${#scenario_name} - ${#scenario_desc} - 1))
		dashes=$(printf '%*s' "$dash_count" | tr ' ' '-')
		if [ "$flg_use_quiet_mode" == "false" ]; then
			echo -e "$scenario_name $scenario_desc response:\n$(echo "$response" | jq)"
		else
			echo "$scenario_name $scenario_desc $dashes Status code: $(print_status_code "$response")"
		fi
	fi





	scenario_number="07-1"
	scenario_name="Scenario $scenario_number"
	scenario_desc="(unit type: PLT)"
	if [[ ("$flg_all" == "true" || " ${scenarios_to_run[@]} " =~ " $scenario_number ") && ! " ${scenarios_to_exclude[@]} " =~ " $scenario_number " ]]; then
		# Scenario 07-1 (unit type: PLT)
		if [ "$flg_unit_supported" == "true" ]; then
			request_data=$(cat <<-EOF
				{
					"originAddress": {
						"postalCode": "60010",
						"addressLines": [],
						"city": "BARRINGTON $scenario_name",
						"state": "IL",
						"country": "US"
					},
					"destinationAddress": {
						"postalCode": "90210",
						"addressLines": [],
						"city": "BEVERLY HILLS $scenario_name",
						"state": "CA",
						"country": "US"
					},
					"enhancedHandlingUnits": [
						{
						"commodityType": "string",
						"contact": {
						"companyName": "string",
						"contactName": "string",
						"email": "string",
						"faxNumber": "string",
						"faxNumberCountryCode": "string",
						"phoneNumber": "string",
						"phoneNumber2": "string",
						"phoneNumber2CountryCode": "string",
						"phoneNumberCountryCode": "string"
						},
						"deliveryStopNumber": 0,
						"description": "string",
						"freightClasses": [
						"50"
						],
						"handlingUnitDimensions": {
						"height": 0,
						"length": 0,
						"width": 0
						},
						"handlingUnitQuantity": 0,
						"handlingUnitType": "PLT",
						"harmonizedCode": "string",
						"nmfcCodes": [
						{
							"code": "string"
						}
						],
						"packages": [
						{
							"contact": {
							"companyName": "string",
							"contactName": "string",
							"email": "string",
							"faxNumber": "string",
							"faxNumberCountryCode": "string",
							"phoneNumber": "string",
							"phoneNumber2": "string",
							"phoneNumber2CountryCode": "string",
							"phoneNumberCountryCode": "string"
							},
							"description": "string",
							"freightClass": "50",
							"involvedParties": [
							{
								"partyIdentifiers": [
								null
								]
							}
							],
							"nmfcCodes": [
							{
								"code": "string"
							}
							],
							"packageContainerType": "BAG",
							"packageContents": [
							{
								"countryOfManufacture": "US",
								"description": "string",
								"hazmatDetails": [
								null
								],
								"packageContentIdentifiers": [
								null
								],
								"packageContentQuantity": 0
							}
							],
							"packageDimensions": {
							"height": 0,
							"length": 0,
							"width": 0
							},
							"packageQuantity": 0,
							"weightPerPackage": 0
						}
						],
						"pickupStopNumber": 0,
						"stackable": true,
						"totalValue": {
						"amount": 0,
						"currency": "USD"
						},
						"weightPerHandlingUnit": 0
					}
					],
					"lineItems": [
						{
							"totalWeight": "100",
							"packageDimensions": {
								"length": "12",
								"width": "12",
								"height": "12"
							},
							"packageType": "PLT",
							"totalPackages": 1,
							"totalPieces": 1,
							"freightClass": "50",
							"description": "$scenario_name"
						}
					],
					"capacityProviderAccountGroup": {
						"code": "$account_group",
						"accounts": [
							{
								"code": "$scac"
							}
						]
					},
					"accessorialServices": [],
					"pickupWindow": {
						"date": "$(date -d 'tomorrow' +'%Y-%m-%d')",
						"startTime": "$(date -d 'tomorrow' +'%H:%M')",
						"endTime": "$(date -d 'tomorrow 6 hours' +'%H:%M')"
					},
					"deliveryWindow":{
					"date": "$(date -d '2 days' +'%Y-%m-%d')",
					"startTime": "$(date -d '2 days 3 hours' +'%H:%M')",
					"endTime": "$(date -d '2 days 6 hours' +'%H:%M')"
				},
				"preferredCurrency": "USD",
					"totalLinearFeet": null,
					"linearFeetVisualizationIdentifier": null,
					"weightUnit": "LB",
					"lengthUnit": "IN",
					"apiConfiguration": {
						"enableUnitConversion": true,
						"accessorialServiceConfiguration": {
							"fetchAllServiceLevels": true,
							"allowUnacceptedAccessorials": false
						}
					}
				}
			EOF
			)

			curl_call=$(cat <<-EOF
				$curl_template '$request_data'
			EOF
			)
			
		if [ "$flg_generate_output" == "true" ]; then
			echo "$curl_call" > "$(pwd)/$output_folder/${curl_call_scenario_file_prefix}_$scenario_number.txt"
		fi
			response=$(eval "$curl_call" | jq)
			dash_count=$(($total_status_output_length - ${#scenario_name} - ${#scenario_desc} - 1))
			dashes=$(printf '%*s' "$dash_count" | tr ' ' '-')
			echo "$scenario_name $scenario_desc $dashes Status code: $(print_status_code "$response")"
		else
			dash_count=$(($total_status_output_length - ${#scenario_name} - ${#scenario_desc} - 1))
			dashes=$(printf '%*s' "$dash_count" | tr ' ' '-')
			echo "$scenario_name $scenario_desc $dashes $(print_error "Handling unit not supported!")"
		fi
	fi




	scenario_number="07-2"
	scenario_name="Scenario $scenario_number"
	scenario_desc="(unit type: CARTON)"
	if [[ ("$flg_all" == "true" || " ${scenarios_to_run[@]} " =~ " $scenario_number ") && ! " ${scenarios_to_exclude[@]} " =~ " $scenario_number " ]]; then
		# Scenario 07-2 (unit type: CARTON)
		if [ "$flg_unit_supported" == "true" ]; then
			request_data=$(cat <<-EOF
				{
					"originAddress": {
						"postalCode": "60010",
						"addressLines": [],
						"city": "BARRINGTON $scenario_name",
						"state": "IL",
						"country": "US"
					},
					"destinationAddress": {
						"postalCode": "90210",
						"addressLines": [],
						"city": "BEVERLY HILLS $scenario_name",
						"state": "CA",
						"country": "US"
					},
					"enhancedHandlingUnits": [
						{
						"commodityType": "string",
						"contact": {
						"companyName": "string",
						"contactName": "string",
						"email": "string",
						"faxNumber": "string",
						"faxNumberCountryCode": "string",
						"phoneNumber": "string",
						"phoneNumber2": "string",
						"phoneNumber2CountryCode": "string",
						"phoneNumberCountryCode": "string"
						},
						"deliveryStopNumber": 0,
						"description": "string",
						"freightClasses": [
						"50"
						],
						"handlingUnitDimensions": {
						"height": 0,
						"length": 0,
						"width": 0
						},
						"handlingUnitQuantity": 0,
						"handlingUnitType": "CARTON",
						"harmonizedCode": "string",
						"nmfcCodes": [
						{
							"code": "string"
						}
						],
						"packages": [
						{
							"contact": {
							"companyName": "string",
							"contactName": "string",
							"email": "string",
							"faxNumber": "string",
							"faxNumberCountryCode": "string",
							"phoneNumber": "string",
							"phoneNumber2": "string",
							"phoneNumber2CountryCode": "string",
							"phoneNumberCountryCode": "string"
							},
							"description": "string",
							"freightClass": "50",
							"involvedParties": [
							{
								"partyIdentifiers": [
								null
								]
							}
							],
							"nmfcCodes": [
							{
								"code": "string"
							}
							],
							"packageContainerType": "BAG",
							"packageContents": [
							{
								"countryOfManufacture": "US",
								"description": "string",
								"hazmatDetails": [
								null
								],
								"packageContentIdentifiers": [
								null
								],
								"packageContentQuantity": 0
							}
							],
							"packageDimensions": {
							"height": 0,
							"length": 0,
							"width": 0
							},
							"packageQuantity": 0,
							"weightPerPackage": 0
						}
						],
						"pickupStopNumber": 0,
						"stackable": true,
						"totalValue": {
						"amount": 0,
						"currency": "USD"
						},
						"weightPerHandlingUnit": 0
					}
					],
					"lineItems": [
						{
							"totalWeight": "100",
							"packageDimensions": {
								"length": "12",
								"width": "12",
								"height": "12"
							},
							"packageType": "PLT",
							"totalPackages": 1,
							"totalPieces": 1,
							"freightClass": "50",
							"description": "$scenario_name"
						}
					],
					"capacityProviderAccountGroup": {
						"code": "$account_group",
						"accounts": [
							{
								"code": "$scac"
							}
						]
					},
					"accessorialServices": [],
					"pickupWindow": {
						"date": "$(date -d 'tomorrow' +'%Y-%m-%d')",
						"startTime": "$(date -d 'tomorrow' +'%H:%M')",
						"endTime": "$(date -d 'tomorrow 6 hours' +'%H:%M')"
					},
					"deliveryWindow":{
					"date": "$(date -d '2 days' +'%Y-%m-%d')",
					"startTime": "$(date -d '2 days 3 hours' +'%H:%M')",
					"endTime": "$(date -d '2 days 6 hours' +'%H:%M')"
				},
				"preferredCurrency": "USD",
					"totalLinearFeet": null,
					"linearFeetVisualizationIdentifier": null,
					"weightUnit": "LB",
					"lengthUnit": "IN",
					"apiConfiguration": {
						"enableUnitConversion": true,
						"accessorialServiceConfiguration": {
							"fetchAllServiceLevels": true,
							"allowUnacceptedAccessorials": false
						}
					}
				}
			EOF
			)

			curl_call=$(cat <<-EOF
				$curl_template '$request_data'
			EOF
			)
			
		if [ "$flg_generate_output" == "true" ]; then
			echo "$curl_call" > "$(pwd)/$output_folder/${curl_call_scenario_file_prefix}_$scenario_number.txt"
		fi
			response=$(eval "$curl_call" | jq)
			echo "$scenario_name $scenario_desc ---- Status code: $(print_status_code "$response")"
		else
			dash_count=$(($total_status_output_length - ${#scenario_name} - ${#scenario_desc} - 1))
			dashes=$(printf '%*s' "$dash_count" | tr ' ' '-')
			echo "$scenario_name $scenario_desc $dashes $(print_error "Handling unit not supported!")"
		fi
	fi





	scenario_number="07-3"
	scenario_name="Scenario $scenario_number"
	scenario_desc="(unit type: TOTE)"
	if [[ ("$flg_all" == "true" || " ${scenarios_to_run[@]} " =~ " $scenario_number ") && ! " ${scenarios_to_exclude[@]} " =~ " $scenario_number " ]]; then
		# Scenario 07-3 (unit type: TOTE)		
		if [ "$flg_unit_supported" == "true" ]; then
			request_data=$(cat <<-EOF
				{
					"originAddress": {
						"postalCode": "60010",
						"addressLines": [],
						"city": "BARRINGTON $scenario_name",
						"state": "IL",
						"country": "US"
					},
					"destinationAddress": {
						"postalCode": "90210",
						"addressLines": [],
						"city": "BEVERLY HILLS $scenario_name",
						"state": "CA",
						"country": "US"
					},
					"enhancedHandlingUnits": [
						{
						"commodityType": "string",
						"contact": {
						"companyName": "string",
						"contactName": "string",
						"email": "string",
						"faxNumber": "string",
						"faxNumberCountryCode": "string",
						"phoneNumber": "string",
						"phoneNumber2": "string",
						"phoneNumber2CountryCode": "string",
						"phoneNumberCountryCode": "string"
						},
						"deliveryStopNumber": 0,
						"description": "string",
						"freightClasses": [
						"50"
						],
						"handlingUnitDimensions": {
						"height": 0,
						"length": 0,
						"width": 0
						},
						"handlingUnitQuantity": 0,
						"handlingUnitType": "TOTE",
						"harmonizedCode": "string",
						"nmfcCodes": [
						{
							"code": "string"
						}
						],
						"packages": [
						{
							"contact": {
							"companyName": "string",
							"contactName": "string",
							"email": "string",
							"faxNumber": "string",
							"faxNumberCountryCode": "string",
							"phoneNumber": "string",
							"phoneNumber2": "string",
							"phoneNumber2CountryCode": "string",
							"phoneNumberCountryCode": "string"
							},
							"description": "string",
							"freightClass": "50",
							"involvedParties": [
							{
								"partyIdentifiers": [
								null
								]
							}
							],
							"nmfcCodes": [
							{
								"code": "string"
							}
							],
							"packageContainerType": "BAG",
							"packageContents": [
							{
								"countryOfManufacture": "US",
								"description": "string",
								"hazmatDetails": [
								null
								],
								"packageContentIdentifiers": [
								null
								],
								"packageContentQuantity": 0
							}
							],
							"packageDimensions": {
							"height": 0,
							"length": 0,
							"width": 0
							},
							"packageQuantity": 0,
							"weightPerPackage": 0
						}
						],
						"pickupStopNumber": 0,
						"stackable": true,
						"totalValue": {
						"amount": 0,
						"currency": "USD"
						},
						"weightPerHandlingUnit": 0
					}
					],
					"lineItems": [
						{
							"totalWeight": "100",
							"packageDimensions": {
								"length": "12",
								"width": "12",
								"height": "12"
							},
							"packageType": "PLT",
							"totalPackages": 1,
							"totalPieces": 1,
							"freightClass": "50",
							"description": "$scenario_name"
						}
					],
					"capacityProviderAccountGroup": {
						"code": "$account_group",
						"accounts": [
							{
								"code": "$scac"
							}
						]
					},
					"accessorialServices": [],
					"pickupWindow": {
						"date": "$(date -d 'tomorrow' +'%Y-%m-%d')",
						"startTime": "$(date -d 'tomorrow' +'%H:%M')",
						"endTime": "$(date -d 'tomorrow 6 hours' +'%H:%M')"
					},
					"deliveryWindow":{
					"date": "$(date -d '2 days' +'%Y-%m-%d')",
					"startTime": "$(date -d '2 days 3 hours' +'%H:%M')",
					"endTime": "$(date -d '2 days 6 hours' +'%H:%M')"
				},
				"preferredCurrency": "USD",
					"totalLinearFeet": null,
					"linearFeetVisualizationIdentifier": null,
					"weightUnit": "LB",
					"lengthUnit": "IN",
					"apiConfiguration": {
						"enableUnitConversion": true,
						"accessorialServiceConfiguration": {
							"fetchAllServiceLevels": true,
							"allowUnacceptedAccessorials": false
						}
					}
				}
			EOF
			)

			curl_call=$(cat <<-EOF
				$curl_template '$request_data'
			EOF
			)
			
		if [ "$flg_generate_output" == "true" ]; then
			echo "$curl_call" > "$(pwd)/$output_folder/${curl_call_scenario_file_prefix}_$scenario_number.txt"
		fi
			response=$(eval "$curl_call" | jq)
			echo "$scenario_name $scenario_desc ---- Status code: $(print_status_code "$response")"
		else
			dash_count=$(($total_status_output_length - ${#scenario_name} - ${#scenario_desc} - 1))
			dashes=$(printf '%*s' "$dash_count" | tr ' ' '-')
			echo "$scenario_name $scenario_desc $dashes $(print_error "Handling unit not supported!")"
		fi
	fi





	scenario_number="08-1"
	scenario_name="Scenario $scenario_number"
	scenario_desc="(accessorial code: HAZM)"
	if [[ ("$flg_all" == "true" || " ${scenarios_to_run[@]} " =~ " $scenario_number ") && ! " ${scenarios_to_exclude[@]} " =~ " $scenario_number " ]]; then
		# Scenario 08-1 (accessorial code: HAZM)
		request_data=$(cat <<-EOF
			{
				"originAddress": {
					"postalCode": "60010",
					"addressLines": [],
					"city": "BARRINGTON $scenario_name",
					"state": "IL",
					"country": "US"
				},
				"destinationAddress": {
					"postalCode": "90210",
					"addressLines": [],
					"city": "BEVERLY HILLS $scenario_name",
					"state": "CA",
					"country": "US"
				},
				"lineItems": [
					{
						"totalWeight": "100",
						"packageDimensions": {
							"length": "12",
							"width": "12",
							"height": "12"
						},
						"packageType": "PLT",
						"totalPackages": 1,
						"totalPieces": 1,
						"freightClass": "50",
						"description": "$scenario_name"
					}
				],
				"capacityProviderAccountGroup": {
					"code": "$account_group",
					"accounts": [
						{
							"code": "$scac"
						}
					]
				},
				"accessorialServices": [
					{
						"code": "HAZM"
					}
				],
				"pickupWindow": {
						"date": "$(date -d 'tomorrow' +'%Y-%m-%d')",
						"startTime": "$(date -d 'tomorrow' +'%H:%M')",
						"endTime": "$(date -d 'tomorrow 6 hours' +'%H:%M')"
				},
				"deliveryWindow":{
					"date": "$(date -d '2 days' +'%Y-%m-%d')",
					"startTime": "$(date -d '2 days 3 hours' +'%H:%M')",
					"endTime": "$(date -d '2 days 6 hours' +'%H:%M')"
				},
				"preferredCurrency": "USD",
				"totalLinearFeet": null,
				"linearFeetVisualizationIdentifier": null,
				"weightUnit": "LB",
				"lengthUnit": "IN",
				"apiConfiguration": {
					"enableUnitConversion": true,
					"accessorialServiceConfiguration": {
						"fetchAllServiceLevels": true,
						"allowUnacceptedAccessorials": false
					}
				}
			}
		EOF
		)

		curl_call=$(cat <<-EOF
			$curl_template '$request_data'
		EOF
		)
		
		if [ "$flg_generate_output" == "true" ]; then
			echo "$curl_call" > "$(pwd)/$output_folder/${curl_call_scenario_file_prefix}_$scenario_number.txt"
		fi
		response=$(eval "$curl_call" | jq)
		dash_count=$(($total_status_output_length - ${#scenario_name} - ${#scenario_desc} - 1))
		dashes=$(printf '%*s' "$dash_count" | tr ' ' '-')
		if [ "$flg_use_quiet_mode" == "false" ]; then
			echo -e "$scenario_name $scenario_desc response:\n$(echo "$response" | jq)"
		else
			echo "$scenario_name $scenario_desc $dashes Status code: $(print_status_code "$response")"
		fi
	fi





	scenario_number="08-2"
	scenario_name="Scenario $scenario_number"
	scenario_desc="(accessorial code: POISON)"
	if [[ ("$flg_all" == "true" || " ${scenarios_to_run[@]} " =~ " $scenario_number ") && ! " ${scenarios_to_exclude[@]} " =~ " $scenario_number " ]]; then
		# Scenario 08-2 (accessorial code: POISON)
		request_data=$(cat <<-EOF
			{
				"originAddress": {
					"postalCode": "60010",
					"addressLines": [],
					"city": "BARRINGTON $scenario_name",
					"state": "IL",
					"country": "US"
				},
				"destinationAddress": {
					"postalCode": "90210",
					"addressLines": [],
					"city": "BEVERLY HILLS $scenario_name",
					"state": "CA",
					"country": "US"
				},
				"lineItems": [
					{
						"totalWeight": "100",
						"packageDimensions": {
							"length": "12",
							"width": "12",
							"height": "12"
						},
						"packageType": "PLT",
						"totalPackages": 1,
						"totalPieces": 1,
						"freightClass": "50",
						"description": "$scenario_name"
					}
				],
				"capacityProviderAccountGroup": {
					"code": "$account_group",
					"accounts": [
						{
							"code": "$scac"
						}
					]
				},
				"accessorialServices": [
					{
						"code": "POISON"
					}
				],
				"pickupWindow": {
						"date": "$(date -d 'tomorrow' +'%Y-%m-%d')",
						"startTime": "$(date -d 'tomorrow' +'%H:%M')",
						"endTime": "$(date -d 'tomorrow 6 hours' +'%H:%M')"
				},
				"deliveryWindow":{
					"date": "$(date -d '2 days' +'%Y-%m-%d')",
					"startTime": "$(date -d '2 days 3 hours' +'%H:%M')",
					"endTime": "$(date -d '2 days 6 hours' +'%H:%M')"
				},
				"preferredCurrency": "USD",
				"totalLinearFeet": null,
				"linearFeetVisualizationIdentifier": null,
				"weightUnit": "LB",
				"lengthUnit": "IN",
				"apiConfiguration": {
					"enableUnitConversion": true,
					"accessorialServiceConfiguration": {
						"fetchAllServiceLevels": true,
						"allowUnacceptedAccessorials": false
					}
				}
			}
		EOF
		)

		curl_call=$(cat <<-EOF
			$curl_template '$request_data'
		EOF
		)
		
		if [ "$flg_generate_output" == "true" ]; then
			echo "$curl_call" > "$(pwd)/$output_folder/${curl_call_scenario_file_prefix}_$scenario_number.txt"
		fi
		response=$(eval "$curl_call" | jq)
		dash_count=$(($total_status_output_length - ${#scenario_name} - ${#scenario_desc} - 1))
		dashes=$(printf '%*s' "$dash_count" | tr ' ' '-')
		if [ "$flg_use_quiet_mode" == "false" ]; then
			echo -e "$scenario_name $scenario_desc response:\n$(echo "$response" | jq)"
		else
			echo "$scenario_name $scenario_desc $dashes Status code: $(print_status_code "$response")"
		fi
	fi





	scenario_number="09-1"
	scenario_name="Scenario $scenario_number"
	scenario_desc="(service level: CNVPU)"
	if [[ ("$flg_all" == "true" || " ${scenarios_to_run[@]} " =~ " $scenario_number ") && ! " ${scenarios_to_exclude[@]} " =~ " $scenario_number " ]]; then
		# Scenario 09-1 (service level: CNVPU)
		request_data=$(cat <<-EOF
			{
				"originAddress": {
					"postalCode": "60010",
					"addressLines": [],
					"city": "BARRINGTON $scenario_name",
					"state": "IL",
					"country": "US"
				},
				"destinationAddress": {
					"postalCode": "90210",
					"addressLines": [],
					"city": "BEVERLY HILLS $scenario_name",
					"state": "CA",
					"country": "US"
				},
				"lineItems": [
					{
						"totalWeight": "100",
						"packageDimensions": {
							"length": "12",
							"width": "12",
							"height": "12"
						},
						"packageType": "PLT",
						"totalPackages": 1,
						"totalPieces": 1,
						"freightClass": "50",
						"description": "$scenario_name"
					}
				],
				"capacityProviderAccountGroup": {
					"code": "$account_group",
					"accounts": [
						{
							"code": "$scac"
						}
					]
				},
				"accessorialServices": [
					{
						"code": "CNVPU"
					}
				],
				"pickupWindow": {
						"date": "$(date -d 'tomorrow' +'%Y-%m-%d')",
						"startTime": "$(date -d 'tomorrow' +'%H:%M')",
						"endTime": "$(date -d 'tomorrow 6 hours' +'%H:%M')"
				},
				"deliveryWindow":{
					"date": "$(date -d '2 days' +'%Y-%m-%d')",
					"startTime": "$(date -d '2 days 3 hours' +'%H:%M')",
					"endTime": "$(date -d '2 days 6 hours' +'%H:%M')"
				},
				"preferredCurrency": "USD",
				"totalLinearFeet": null,
				"linearFeetVisualizationIdentifier": null,
				"weightUnit": "LB",
				"lengthUnit": "IN",
				"apiConfiguration": {
					"enableUnitConversion": true,
					"accessorialServiceConfiguration": {
						"fetchAllServiceLevels": true,
						"allowUnacceptedAccessorials": false
					}
				}
			}
		EOF
		)

		curl_call=$(cat <<-EOF
			$curl_template '$request_data'
		EOF
		)
		
		if [ "$flg_generate_output" == "true" ]; then
			echo "$curl_call" > "$(pwd)/$output_folder/${curl_call_scenario_file_prefix}_$scenario_number.txt"
		fi
		response=$(eval "$curl_call" | jq)
		dash_count=$(($total_status_output_length - ${#scenario_name} - ${#scenario_desc} - 1))
		dashes=$(printf '%*s' "$dash_count" | tr ' ' '-')
		if [ "$flg_use_quiet_mode" == "false" ]; then
			echo -e "$scenario_name $scenario_desc response:\n$(echo "$response" | jq)"
		else
			echo "$scenario_name $scenario_desc $dashes Status code: $(print_status_code "$response")"
		fi
	fi





	scenario_number="09-2"
	scenario_name="Scenario $scenario_number"
	scenario_desc="(service level: INPU)"
	if [[ ("$flg_all" == "true" || " ${scenarios_to_run[@]} " =~ " $scenario_number ") && ! " ${scenarios_to_exclude[@]} " =~ " $scenario_number " ]]; then
		# Scenario 09-2 (service level: INPU)
		request_data=$(cat <<-EOF
			{
				"originAddress": {
					"postalCode": "60010",
					"addressLines": [],
					"city": "BARRINGTON $scenario_name",
					"state": "IL",
					"country": "US"
				},
				"destinationAddress": {
					"postalCode": "90210",
					"addressLines": [],
					"city": "BEVERLY HILLS $scenario_name",
					"state": "CA",
					"country": "US"
				},
				"lineItems": [
					{
						"totalWeight": "100",
						"packageDimensions": {
							"length": "12",
							"width": "12",
							"height": "12"
						},
						"packageType": "PLT",
						"totalPackages": 1,
						"totalPieces": 1,
						"freightClass": "50",
						"description": "$scenario_name"
					}
				],
				"capacityProviderAccountGroup": {
					"code": "$account_group",
					"accounts": [
						{
							"code": "$scac"
						}
					]
				},
				"accessorialServices": [
					{
						"code": "INPU"
					}
				],
				"pickupWindow": {
						"date": "$(date -d 'tomorrow' +'%Y-%m-%d')",
						"startTime": "$(date -d 'tomorrow' +'%H:%M')",
						"endTime": "$(date -d 'tomorrow 6 hours' +'%H:%M')"
				},
				"deliveryWindow":{
					"date": "$(date -d '2 days' +'%Y-%m-%d')",
					"startTime": "$(date -d '2 days 3 hours' +'%H:%M')",
					"endTime": "$(date -d '2 days 6 hours' +'%H:%M')"
				},
				"preferredCurrency": "USD",
				"totalLinearFeet": null,
				"linearFeetVisualizationIdentifier": null,
				"weightUnit": "LB",
				"lengthUnit": "IN",
				"apiConfiguration": {
					"enableUnitConversion": true,
					"accessorialServiceConfiguration": {
						"fetchAllServiceLevels": true,
						"allowUnacceptedAccessorials": false
					}
				}
			}
		EOF
		)

		curl_call=$(cat <<-EOF
			$curl_template '$request_data'
		EOF
		)
		
		if [ "$flg_generate_output" == "true" ]; then
			echo "$curl_call" > "$(pwd)/$output_folder/${curl_call_scenario_file_prefix}_$scenario_number.txt"
		fi
		response=$(eval "$curl_call" | jq)
		dash_count=$(($total_status_output_length - ${#scenario_name} - ${#scenario_desc} - 1))
		dashes=$(printf '%*s' "$dash_count" | tr ' ' '-')
		if [ "$flg_use_quiet_mode" == "false" ]; then
			echo -e "$scenario_name $scenario_desc response:\n$(echo "$response" | jq)"
		else
			echo "$scenario_name $scenario_desc $dashes Status code: $(print_status_code "$response")"
		fi
	fi





	scenario_number="10-1"
	scenario_name="Scenario $scenario_number"
	scenario_desc="(accessorial code: LTDPU)"
	if [[ ("$flg_all" == "true" || " ${scenarios_to_run[@]} " =~ " $scenario_number ") && ! " ${scenarios_to_exclude[@]} " =~ " $scenario_number " ]]; then
		# Scenario 10-1 (accessorial code: LTDPU)
		request_data=$(cat <<-EOF
			{
				"originAddress": {
					"postalCode": "60010",
					"addressLines": [],
					"city": "BARRINGTON $scenario_name",
					"state": "IL",
					"country": "US"
				},
				"destinationAddress": {
					"postalCode": "90210",
					"addressLines": [],
					"city": "BEVERLY HILLS $scenario_name",
					"state": "CA",
					"country": "US"
				},
				"lineItems": [
					{
						"totalWeight": "100",
						"packageDimensions": {
							"length": "12",
							"width": "12",
							"height": "12"
						},
						"packageType": "PLT",
						"totalPackages": 1,
						"totalPieces": 1,
						"freightClass": "50",
						"description": "$scenario_name"
					}
				],
				"capacityProviderAccountGroup": {
					"code": "$account_group",
					"accounts": [
						{
							"code": "$scac"
						}
					]
				},
				"accessorialServices": [
					{
						"code": "LTDPU"
					}
				],
				"pickupWindow": {
						"date": "$(date -d 'tomorrow' +'%Y-%m-%d')",
						"startTime": "$(date -d 'tomorrow' +'%H:%M')",
						"endTime": "$(date -d 'tomorrow 6 hours' +'%H:%M')"
				},
				"deliveryWindow":{
					"date": "$(date -d '2 days' +'%Y-%m-%d')",
					"startTime": "$(date -d '2 days 3 hours' +'%H:%M')",
					"endTime": "$(date -d '2 days 6 hours' +'%H:%M')"
				},
				"preferredCurrency": "USD",
				"totalLinearFeet": null,
				"linearFeetVisualizationIdentifier": null,
				"weightUnit": "LB",
				"lengthUnit": "IN",
				"apiConfiguration": {
					"enableUnitConversion": true,
					"accessorialServiceConfiguration": {
						"fetchAllServiceLevels": true,
						"allowUnacceptedAccessorials": false
					}
				}
			}
		EOF
		)

		curl_call=$(cat <<-EOF
			$curl_template '$request_data'
		EOF
		)
		
		if [ "$flg_generate_output" == "true" ]; then
			echo "$curl_call" > "$(pwd)/$output_folder/${curl_call_scenario_file_prefix}_$scenario_number.txt"
		fi
		response=$(eval "$curl_call" | jq)
		dash_count=$(($total_status_output_length - ${#scenario_name} - ${#scenario_desc} - 1))
		dashes=$(printf '%*s' "$dash_count" | tr ' ' '-')
		if [ "$flg_use_quiet_mode" == "false" ]; then
			echo -e "$scenario_name $scenario_desc response:\n$(echo "$response" | jq)"
		else
			echo "$scenario_name $scenario_desc $dashes Status code: $(print_status_code "$response")"
		fi
	fi





	scenario_number="10-2"
	scenario_name="Scenario $scenario_number"
	scenario_desc="(accessorial code: LTDDEL)"
	if [[ ("$flg_all" == "true" || " ${scenarios_to_run[@]} " =~ " $scenario_number ") && ! " ${scenarios_to_exclude[@]} " =~ " $scenario_number " ]]; then
		# Scenario 10-2 (accessorial code: LTDDEL)
		request_data=$(cat <<-EOF
			{
				"originAddress": {
					"postalCode": "60010",
					"addressLines": [],
					"city": "BARRINGTON $scenario_name",
					"state": "IL",
					"country": "US"
				},
				"destinationAddress": {
					"postalCode": "90210",
					"addressLines": [],
					"city": "BEVERLY HILLS $scenario_name",
					"state": "CA",
					"country": "US"
				},
				"lineItems": [
					{
						"totalWeight": "100",
						"packageDimensions": {
							"length": "12",
							"width": "12",
							"height": "12"
						},
						"packageType": "PLT",
						"totalPackages": 1,
						"totalPieces": 1,
						"freightClass": "50",
						"description": "$scenario_name"
					}
				],
				"capacityProviderAccountGroup": {
					"code": "$account_group",
					"accounts": [
						{
							"code": "$scac"
						}
					]
				},
				"accessorialServices": [
					{
						"code": "LTDDEL"
					}
				],
				"pickupWindow": {
						"date": "$(date -d 'tomorrow' +'%Y-%m-%d')",
						"startTime": "$(date -d 'tomorrow' +'%H:%M')",
						"endTime": "$(date -d 'tomorrow 6 hours' +'%H:%M')"
				},
				"deliveryWindow":{
					"date": "$(date -d '2 days' +'%Y-%m-%d')",
					"startTime": "$(date -d '2 days 3 hours' +'%H:%M')",
					"endTime": "$(date -d '2 days 6 hours' +'%H:%M')"
				},
				"preferredCurrency": "USD",
				"totalLinearFeet": null,
				"linearFeetVisualizationIdentifier": null,
				"weightUnit": "LB",
				"lengthUnit": "IN",
				"apiConfiguration": {
					"enableUnitConversion": true,
					"accessorialServiceConfiguration": {
						"fetchAllServiceLevels": true,
						"allowUnacceptedAccessorials": false
					}
				}
			}
		EOF
		)

		curl_call=$(cat <<-EOF
			$curl_template '$request_data'
		EOF
		)
		
		if [ "$flg_generate_output" == "true" ]; then
			echo "$curl_call" > "$(pwd)/$output_folder/${curl_call_scenario_file_prefix}_$scenario_number.txt"
		fi
		response=$(eval "$curl_call" | jq)
		dash_count=$(($total_status_output_length - ${#scenario_name} - ${#scenario_desc} - 1))
		dashes=$(printf '%*s' "$dash_count" | tr ' ' '-')
		if [ "$flg_use_quiet_mode" == "false" ]; then
			echo -e "$scenario_name $scenario_desc response:\n$(echo "$response" | jq)"
		else
			echo "$scenario_name $scenario_desc $dashes Status code: $(print_status_code "$response")"
		fi
	fi





	scenario_number="11-1"
	scenario_name="Scenario $scenario_number"
	scenario_desc="(charge code: valid)"
	if [[ ("$flg_all" == "true" || " ${scenarios_to_run[@]} " =~ " $scenario_number ") && ! " ${scenarios_to_exclude[@]} " =~ " $scenario_number " ]]; then
		# Scenario 11-1 (charge code: valid)
		request_data=$(cat <<-EOF
			{
				"originAddress": {
					"postalCode": "60010",
					"addressLines": [],
					"city": "BARRINGTON $scenario_name",
					"state": "IL",
					"country": "US"
				},
				"destinationAddress": {
					"postalCode": "90210",
					"addressLines": [],
					"city": "BEVERLY HILLS $scenario_name",
					"state": "CA",
					"country": "US"
				},
				"lineItems": [
					{
						"totalWeight": "100",
						"packageDimensions": {
							"length": "12",
							"width": "12",
							"height": "12"
						},
						"packageType": "PLT",
						"totalPackages": 1,
						"totalPieces": 1,
						"freightClass": "50",
						"description": "$scenario_name"
					}
				],
				"capacityProviderAccountGroup": {
					"code": "$account_group",
					"accounts": [
						{
							"code": "$scac"
						}
					]
				},
				"accessorialServices": [
					{
						"code": "$acc_code"
					}
				],
				"pickupWindow": {
						"date": "$(date -d 'tomorrow' +'%Y-%m-%d')",
						"startTime": "$(date -d 'tomorrow' +'%H:%M')",
						"endTime": "$(date -d 'tomorrow 6 hours' +'%H:%M')"
				},
				"deliveryWindow":{
					"date": "$(date -d '2 days' +'%Y-%m-%d')",
					"startTime": "$(date -d '2 days 3 hours' +'%H:%M')",
					"endTime": "$(date -d '2 days 6 hours' +'%H:%M')"
				},
				"preferredCurrency": "USD",
				"totalLinearFeet": null,
				"linearFeetVisualizationIdentifier": null,
				"weightUnit": "LB",
				"lengthUnit": "IN",
				"apiConfiguration": {
					"enableUnitConversion": true,
					"accessorialServiceConfiguration": {
						"fetchAllServiceLevels": true,
						"allowUnacceptedAccessorials": false
					}
				}
			}
		EOF
		)

		curl_call=$(cat <<-EOF
			$curl_template '$request_data'
		EOF
		)
		
		if [ "$flg_generate_output" == "true" ]; then
			echo "$curl_call" > "$(pwd)/$output_folder/${curl_call_scenario_file_prefix}_$scenario_number.txt"
		fi
		response=$(eval "$curl_call" | jq)
		dash_count=$(($total_status_output_length - ${#scenario_name} - ${#scenario_desc} - 1))
		dashes=$(printf '%*s' "$dash_count" | tr ' ' '-')
		if [ "$flg_use_quiet_mode" == "false" ]; then
			echo -e "$scenario_name $scenario_desc response:\n$(echo "$response" | jq)"
		else
			echo "$scenario_name $scenario_desc $dashes Status code: $(print_status_code "$response")"
		fi
	fi




	scenario_number="11-2"
	scenario_name="Scenario $scenario_number"
	scenario_desc="(charge code: invalid)"
	if [[ ("$flg_all" == "true" || " ${scenarios_to_run[@]} " =~ " $scenario_number ") && ! " ${scenarios_to_exclude[@]} " =~ " $scenario_number " ]]; then
		# Scenario 11-2 (charge code: invalid)
		request_data=$(cat <<-EOF
			{
				"originAddress": {
					"postalCode": "60010",
					"addressLines": [],
					"city": "BARRINGTON $scenario_name",
					"state": "IL",
					"country": "US"
				},
				"destinationAddress": {
					"postalCode": "90210",
					"addressLines": [],
					"city": "BEVERLY HILLS $scenario_name",
					"state": "CA",
					"country": "US"
				},
				"lineItems": [
					{
						"totalWeight": "100",
						"packageDimensions": {
							"length": "12",
							"width": "12",
							"height": "12"
						},
						"packageType": "PLT",
						"totalPackages": 1,
						"totalPieces": 1,
						"freightClass": "50",
						"description": "$scenario_name"
					}
				],
				"capacityProviderAccountGroup": {
					"code": "$account_group",
					"accounts": [
						{
							"code": "$scac"
						}
					]
				},
				"accessorialServices": [],
				"pickupWindow": {
						"date": "$(date -d 'tomorrow' +'%Y-%m-%d')",
						"startTime": "$(date -d 'tomorrow' +'%H:%M')",
						"endTime": "$(date -d 'tomorrow 6 hours' +'%H:%M')"
				},
				"deliveryWindow":{
					"date": "$(date -d '2 days' +'%Y-%m-%d')",
					"startTime": "$(date -d '2 days 3 hours' +'%H:%M')",
					"endTime": "$(date -d '2 days 6 hours' +'%H:%M')"
				},
				"preferredCurrency": "USD",
				"totalLinearFeet": null,
				"linearFeetVisualizationIdentifier": null,
				"weightUnit": "LB",
				"lengthUnit": "IN",
				"apiConfiguration": {
					"enableUnitConversion": true,
					"accessorialServiceConfiguration": {
						"fetchAllServiceLevels": true,
						"allowUnacceptedAccessorials": false
					}
				}
			}
		EOF
		)

		curl_call=$(cat <<-EOF
			$curl_template '$request_data'
		EOF
		)
		
		if [ "$flg_generate_output" == "true" ]; then
			echo "$curl_call" > "$(pwd)/$output_folder/${curl_call_scenario_file_prefix}_$scenario_number.txt"
		fi
		response=$(eval "$curl_call" | jq)
		dash_count=$(($total_status_output_length - ${#scenario_name} - ${#scenario_desc} - 1))
		dashes=$(printf '%*s' "$dash_count" | tr ' ' '-')
		if [ "$flg_use_quiet_mode" == "false" ]; then
			echo -e "$scenario_name $scenario_desc response:\n$(echo "$response" | jq)"
		else
			echo "$scenario_name $scenario_desc $dashes Status code: $(print_status_code "$response")"
		fi
	fi





	scenario_number="12-1"
	scenario_name="Scenario $scenario_number"
	scenario_desc="(1 line item)"
	if [[ ("$flg_all" == "true" || " ${scenarios_to_run[@]} " =~ " $scenario_number ") && ! " ${scenarios_to_exclude[@]} " =~ " $scenario_number " ]]; then
		# Scenario 12-1 (1 line item)
		request_data=$(cat <<-EOF
			{
				"originAddress": {
					"postalCode": "60010",
					"addressLines": [],
					"city": "BARRINGTON $scenario_name",
					"state": "IL",
					"country": "US"
				},
				"destinationAddress": {
					"postalCode": "90210",
					"addressLines": [],
					"city": "BEVERLY HILLS $scenario_name",
					"state": "CA",
					"country": "US"
				},
				"lineItems": [
					{
						"totalWeight": "100",
						"packageDimensions": {
							"length": "12",
							"width": "12",
							"height": "12"
						},
						"packageType": "PLT",
						"totalPackages": 1,
						"totalPieces": 1,
						"freightClass": "50",
						"description": "$scenario_name"
					}
				],
				"capacityProviderAccountGroup": {
					"code": "$account_group",
					"accounts": [
						{
							"code": "$scac"
						}
					]
				},
				"accessorialServices": [],
				"pickupWindow": {
						"date": "$(date -d 'tomorrow' +'%Y-%m-%d')",
						"startTime": "$(date -d 'tomorrow' +'%H:%M')",
						"endTime": "$(date -d 'tomorrow 6 hours' +'%H:%M')"
				},
				"deliveryWindow":{
					"date": "$(date -d '2 days' +'%Y-%m-%d')",
					"startTime": "$(date -d '2 days 3 hours' +'%H:%M')",
					"endTime": "$(date -d '2 days 6 hours' +'%H:%M')"
				},
				"preferredCurrency": "USD",
				"totalLinearFeet": null,
				"linearFeetVisualizationIdentifier": null,
				"weightUnit": "LB",
				"lengthUnit": "IN",
				"apiConfiguration": {
					"enableUnitConversion": true,
					"accessorialServiceConfiguration": {
						"fetchAllServiceLevels": true,
						"allowUnacceptedAccessorials": false
					}
				}
			}
		EOF
		)

		curl_call=$(cat <<-EOF
			$curl_template '$request_data'
		EOF
		)
		
		if [ "$flg_generate_output" == "true" ]; then
			echo "$curl_call" > "$(pwd)/$output_folder/${curl_call_scenario_file_prefix}_$scenario_number.txt"
		fi
		response=$(eval "$curl_call" | jq)
		dash_count=$(($total_status_output_length - ${#scenario_name} - ${#scenario_desc} - 1))
		dashes=$(printf '%*s' "$dash_count" | tr ' ' '-')
		if [ "$flg_use_quiet_mode" == "false" ]; then
			echo -e "$scenario_name $scenario_desc response:\n$(echo "$response" | jq)"
		else
			echo "$scenario_name $scenario_desc $dashes Status code: $(print_status_code "$response")"
		fi
	fi





	scenario_number="12-2"
	scenario_name="Scenario $scenario_number"
	scenario_desc="(5 line items)"
	if [[ ("$flg_all" == "true" || " ${scenarios_to_run[@]} " =~ " $scenario_number ") && ! " ${scenarios_to_exclude[@]} " =~ " $scenario_number " ]]; then
		# Scenario 12-2 (5 line items)
		request_data=$(cat <<-EOF
			{
				"originAddress": {
					"postalCode": "60010",
					"addressLines": [],
					"city": "BARRINGTON $scenario_name",
					"state": "IL",
					"country": "US"
				},
				"destinationAddress": {
					"postalCode": "90210",
					"addressLines": [],
					"city": "BEVERLY HILLS $scenario_name",
					"state": "CA",
					"country": "US"
				},
				"lineItems": [
					{
						"totalWeight": "100",
						"packageDimensions": {
							"length": "12",
							"width": "12",
							"height": "12"
						},
						"packageType": "PLT",
						"totalPackages": 1,
						"totalPieces": 1,
						"freightClass": "50",
						"description": "$scenario_name"
					},
									{
						"totalWeight": "200",
						"packageDimensions": {
							"length": "12",
							"width": "12",
							"height": "12"
						},
						"packageType": "PLT",
						"totalPackages": 1,
						"totalPieces": 1,
						"freightClass": "50",
						"description": "$scenario_name"
					},
									{
						"totalWeight": "300",
						"packageDimensions": {
							"length": "12",
							"width": "12",
							"height": "12"
						},
						"packageType": "PLT",
						"totalPackages": 1,
						"totalPieces": 1,
						"freightClass": "50",
						"description": "$scenario_name"
					},
									{
						"totalWeight": "400",
						"packageDimensions": {
							"length": "12",
							"width": "12",
							"height": "12"
						},
						"packageType": "PLT",
						"totalPackages": 1,
						"totalPieces": 1,
						"freightClass": "50",
						"description": "$scenario_name"
					},
									{
						"totalWeight": "500",
						"packageDimensions": {
							"length": "12",
							"width": "12",
							"height": "12"
						},
						"packageType": "PLT",
						"totalPackages": 1,
						"totalPieces": 1,
						"freightClass": "50",
						"description": "$scenario_name"
					}
				],
				"capacityProviderAccountGroup": {
					"code": "$account_group",
					"accounts": [
						{
							"code": "$scac"
						}
					]
				},
				"accessorialServices": [],
				"pickupWindow": {
						"date": "$(date -d 'tomorrow' +'%Y-%m-%d')",
						"startTime": "$(date -d 'tomorrow' +'%H:%M')",
						"endTime": "$(date -d 'tomorrow 6 hours' +'%H:%M')"
				},
				"deliveryWindow":{
					"date": "$(date -d '2 days' +'%Y-%m-%d')",
					"startTime": "$(date -d '2 days 3 hours' +'%H:%M')",
					"endTime": "$(date -d '2 days 6 hours' +'%H:%M')"
				},
				"preferredCurrency": "USD",
				"totalLinearFeet": null,
				"linearFeetVisualizationIdentifier": null,
				"weightUnit": "LB",
				"lengthUnit": "IN",
				"apiConfiguration": {
					"enableUnitConversion": true,
					"accessorialServiceConfiguration": {
						"fetchAllServiceLevels": true,
						"allowUnacceptedAccessorials": false
					}
				}
			}
		EOF
		)

		curl_call=$(cat <<-EOF
			$curl_template '$request_data'
		EOF
		)
		
		if [ "$flg_generate_output" == "true" ]; then
			echo "$curl_call" > "$(pwd)/$output_folder/${curl_call_scenario_file_prefix}_$scenario_number.txt"
		fi
		response=$(eval "$curl_call" | jq)
		dash_count=$(($total_status_output_length - ${#scenario_name} - ${#scenario_desc} - 1))
		dashes=$(printf '%*s' "$dash_count" | tr ' ' '-')
		if [ "$flg_use_quiet_mode" == "false" ]; then
			echo -e "$scenario_name $scenario_desc response:\n$(echo "$response" | jq)"
		else
			echo "$scenario_name $scenario_desc $dashes Status code: $(print_status_code "$response")"
		fi
	fi



	scenario_number="12-3"
	scenario_name="Scenario $scenario_number"
	scenario_desc="(10 line items)"
	if [[ ("$flg_all" == "true" || " ${scenarios_to_run[@]} " =~ " $scenario_number ") && ! " ${scenarios_to_exclude[@]} " =~ " $scenario_number " ]]; then
		# Scenario 12-3 (10 line items)
		request_data=$(cat <<-EOF
			{
				"originAddress": {
					"postalCode": "60010",
					"addressLines": [],
					"city": "BARRINGTON $scenario_name",
					"state": "IL",
					"country": "US"
				},
				"destinationAddress": {
					"postalCode": "90210",
					"addressLines": [],
					"city": "BEVERLY HILLS $scenario_name",
					"state": "CA",
					"country": "US"
				},
				"lineItems": [
					{
						"totalWeight": "100",
						"packageDimensions": {
							"length": "12",
							"width": "12",
							"height": "12"
						},
						"packageType": "PLT",
						"totalPackages": 1,
						"totalPieces": 1,
						"freightClass": "50",
						"description": "$scenario_name"
					},
									{
						"totalWeight": "200",
						"packageDimensions": {
							"length": "12",
							"width": "12",
							"height": "12"
						},
						"packageType": "PLT",
						"totalPackages": 1,
						"totalPieces": 1,
						"freightClass": "50",
						"description": "$scenario_name"
					},
									{
						"totalWeight": "300",
						"packageDimensions": {
							"length": "12",
							"width": "12",
							"height": "12"
						},
						"packageType": "PLT",
						"totalPackages": 1,
						"totalPieces": 1,
						"freightClass": "50",
						"description": "$scenario_name"
					},
									{
						"totalWeight": "400",
						"packageDimensions": {
							"length": "12",
							"width": "12",
							"height": "12"
						},
						"packageType": "PLT",
						"totalPackages": 1,
						"totalPieces": 1,
						"freightClass": "50",
						"description": "$scenario_name"
					},
									{
						"totalWeight": "500",
						"packageDimensions": {
							"length": "12",
							"width": "12",
							"height": "12"
						},
						"packageType": "PLT",
						"totalPackages": 1,
						"totalPieces": 1,
						"freightClass": "50",
						"description": "$scenario_name"
					},
					{
						"totalWeight": "150",
						"packageDimensions": {
							"length": "12",
							"width": "12",
							"height": "12"
						},
						"packageType": "PLT",
						"totalPackages": 1,
						"totalPieces": 1,
						"freightClass": "50",
						"description": "$scenario_name"
					},
									{
						"totalWeight": "250",
						"packageDimensions": {
							"length": "12",
							"width": "12",
							"height": "12"
						},
						"packageType": "PLT",
						"totalPackages": 1,
						"totalPieces": 1,
						"freightClass": "50",
						"description": "$scenario_name"
					},
									{
						"totalWeight": "350",
						"packageDimensions": {
							"length": "12",
							"width": "12",
							"height": "12"
						},
						"packageType": "PLT",
						"totalPackages": 1,
						"totalPieces": 1,
						"freightClass": "50",
						"description": "$scenario_name"
					},
									{
						"totalWeight": "450",
						"packageDimensions": {
							"length": "12",
							"width": "12",
							"height": "12"
						},
						"packageType": "PLT",
						"totalPackages": 1,
						"totalPieces": 1,
						"freightClass": "50",
						"description": "$scenario_name"
					},
									{
						"totalWeight": "550",
						"packageDimensions": {
							"length": "12",
							"width": "12",
							"height": "12"
						},
						"packageType": "PLT",
						"totalPackages": 1,
						"totalPieces": 1,
						"freightClass": "50",
						"description": "$scenario_name"
					}
				],
				"capacityProviderAccountGroup": {
					"code": "$account_group",
					"accounts": [
						{
							"code": "$scac"
						}
					]
				},
				"accessorialServices": [],
				"pickupWindow": {
						"date": "$(date -d 'tomorrow' +'%Y-%m-%d')",
						"startTime": "$(date -d 'tomorrow' +'%H:%M')",
						"endTime": "$(date -d 'tomorrow 6 hours' +'%H:%M')"
				},
				"deliveryWindow":{
					"date": "$(date -d '2 days' +'%Y-%m-%d')",
					"startTime": "$(date -d '2 days 3 hours' +'%H:%M')",
					"endTime": "$(date -d '2 days 6 hours' +'%H:%M')"
				},
				"preferredCurrency": "USD",
				"totalLinearFeet": null,
				"linearFeetVisualizationIdentifier": null,
				"weightUnit": "LB",
				"lengthUnit": "IN",
				"apiConfiguration": {
					"enableUnitConversion": true,
					"accessorialServiceConfiguration": {
						"fetchAllServiceLevels": true,
						"allowUnacceptedAccessorials": false
					}
				}
			}
		EOF
		)

		curl_call=$(cat <<-EOF
			$curl_template '$request_data'
		EOF
		)
		
		if [ "$flg_generate_output" == "true" ]; then
			echo "$curl_call" > "$(pwd)/$output_folder/${curl_call_scenario_file_prefix}_$scenario_number.txt"
		fi
		response=$(eval "$curl_call" | jq)
		dash_count=$(($total_status_output_length - ${#scenario_name} - ${#scenario_desc} - 1))
		dashes=$(printf '%*s' "$dash_count" | tr ' ' '-')
		if [ "$flg_use_quiet_mode" == "false" ]; then
			echo -e "$scenario_name $scenario_desc response:\n$(echo "$response" | jq)"
		else
			echo "$scenario_name $scenario_desc $dashes Status code: $(print_status_code "$response")"
		fi
	fi





	scenario_number="13-1"
	scenario_name="Scenario $scenario_number"
	scenario_desc="(stackable: true)"
	if [[ ("$flg_all" == "true" || " ${scenarios_to_run[@]} " =~ " $scenario_number ") && ! " ${scenarios_to_exclude[@]} " =~ " $scenario_number " ]]; then
		# Scenario 13-1 (stackable: true)
		request_data=$(cat <<-EOF
			{
				"originAddress": {
					"postalCode": "60010",
					"addressLines": [],
					"city": "BARRINGTON $scenario_name",
					"state": "IL",
					"country": "US"
				},
				"destinationAddress": {
					"postalCode": "90210",
					"addressLines": [],
					"city": "BEVERLY HILLS $scenario_name",
					"state": "CA",
					"country": "US"
				},
				"lineItems": [
					{
						"totalWeight": "100",
						"packageDimensions": {
							"length": "12",
							"width": "12",
							"height": "12"
						},
						"packageType": "PLT",
						"totalPackages": 1,
						"totalPieces": 1,
						"freightClass": "50",
						"description": "$scenario_name",
						"stackable": true
					},
									{
						"totalWeight": "200",
						"packageDimensions": {
							"length": "12",
							"width": "12",
							"height": "12"
						},
						"packageType": "PLT",
						"totalPackages": 1,
						"totalPieces": 1,
						"freightClass": "50",
						"description": "$scenario_name",
						"stackable": true
					},
					{
						"totalWeight": "300",
						"packageDimensions": {
							"length": "12",
							"width": "12",
							"height": "12"
						},
						"packageType": "PLT",
						"totalPackages": 1,
						"totalPieces": 1,
						"freightClass": "50",
						"description": "$scenario_name",
						"stackable": true
					}
				],
				"capacityProviderAccountGroup": {
					"code": "$account_group",
					"accounts": [
						{
							"code": "$scac"
						}
					]
				},
				"accessorialServices": [],
				"pickupWindow": {
						"date": "$(date -d 'tomorrow' +'%Y-%m-%d')",
						"startTime": "$(date -d 'tomorrow' +'%H:%M')",
						"endTime": "$(date -d 'tomorrow 6 hours' +'%H:%M')"
				},
				"deliveryWindow":{
					"date": "$(date -d '2 days' +'%Y-%m-%d')",
					"startTime": "$(date -d '2 days 3 hours' +'%H:%M')",
					"endTime": "$(date -d '2 days 6 hours' +'%H:%M')"
				},
				"preferredCurrency": "USD",
				"totalLinearFeet": null,
				"linearFeetVisualizationIdentifier": null,
				"weightUnit": "LB",
				"lengthUnit": "IN",
				"apiConfiguration": {
					"enableUnitConversion": true,
					"accessorialServiceConfiguration": {
						"fetchAllServiceLevels": true,
						"allowUnacceptedAccessorials": false
					}
				}
			}
		EOF
		)

		curl_call=$(cat <<-EOF
			$curl_template '$request_data'
		EOF
		)
		
		if [ "$flg_generate_output" == "true" ]; then
			echo "$curl_call" > "$(pwd)/$output_folder/${curl_call_scenario_file_prefix}_$scenario_number.txt"
		fi
		response=$(eval "$curl_call" | jq)
		dash_count=$(($total_status_output_length - ${#scenario_name} - ${#scenario_desc} - 1))
		dashes=$(printf '%*s' "$dash_count" | tr ' ' '-')
		if [ "$flg_use_quiet_mode" == "false" ]; then
			echo -e "$scenario_name $scenario_desc response:\n$(echo "$response" | jq)"
		else
			echo "$scenario_name $scenario_desc $dashes Status code: $(print_status_code "$response")"
		fi
	fi





	scenario_number="13-2"
	scenario_name="Scenario $scenario_number"
	scenario_desc="(stackable: false)"
	if [[ ("$flg_all" == "true" || " ${scenarios_to_run[@]} " =~ " $scenario_number ") && ! " ${scenarios_to_exclude[@]} " =~ " $scenario_number " ]]; then
		# Scenario 13-2 (stackable false)
		request_data=$(cat <<-EOF
			{
				"originAddress": {
					"postalCode": "60010",
					"addressLines": [],
					"city": "BARRINGTON $scenario_name",
					"state": "IL",
					"country": "US"
				},
				"destinationAddress": {
					"postalCode": "90210",
					"addressLines": [],
					"city": "BEVERLY HILLS $scenario_name",
					"state": "CA",
					"country": "US"
				},
				"lineItems": [
					{
						"totalWeight": "100",
						"packageDimensions": {
							"length": "12",
							"width": "12",
							"height": "12"
						},
						"packageType": "PLT",
						"totalPackages": 1,
						"totalPieces": 1,
						"freightClass": "50",
						"description": "$scenario_name",
						"stackable": false
					},
									{
						"totalWeight": "200",
						"packageDimensions": {
							"length": "12",
							"width": "12",
							"height": "12"
						},
						"packageType": "PLT",
						"totalPackages": 1,
						"totalPieces": 1,
						"freightClass": "50",
						"description": "$scenario_name",
						"stackable": false
					},
									{
						"totalWeight": "300",
						"packageDimensions": {
							"length": "12",
							"width": "12",
							"height": "12"
						},
						"packageType": "PLT",
						"totalPackages": 1,
						"totalPieces": 1,
						"freightClass": "50",
						"description": "$scenario_name",
						"stackable": false
					}
				],
				"capacityProviderAccountGroup": {
					"code": "$account_group",
					"accounts": [
						{
							"code": "$scac"
						}
					]
				},
				"accessorialServices": [],
				"pickupWindow": {
						"date": "$(date -d 'tomorrow' +'%Y-%m-%d')",
						"startTime": "$(date -d 'tomorrow' +'%H:%M')",
						"endTime": "$(date -d 'tomorrow 6 hours' +'%H:%M')"
				},
				"deliveryWindow":{
					"date": "$(date -d '2 days' +'%Y-%m-%d')",
					"startTime": "$(date -d '2 days 3 hours' +'%H:%M')",
					"endTime": "$(date -d '2 days 6 hours' +'%H:%M')"
				},
				"preferredCurrency": "USD",
				"totalLinearFeet": null,
				"linearFeetVisualizationIdentifier": null,
				"weightUnit": "LB",
				"lengthUnit": "IN",
				"apiConfiguration": {
					"enableUnitConversion": true,
					"accessorialServiceConfiguration": {
						"fetchAllServiceLevels": true,
						"allowUnacceptedAccessorials": false
					}
				}
			}
		EOF
		)

		curl_call=$(cat <<-EOF
			$curl_template '$request_data'
		EOF
		)
		
		if [ "$flg_generate_output" == "true" ]; then
			echo "$curl_call" > "$(pwd)/$output_folder/${curl_call_scenario_file_prefix}_$scenario_number.txt"
		fi
		response=$(eval "$curl_call" | jq)
		dash_count=$(($total_status_output_length - ${#scenario_name} - ${#scenario_desc} - 1))
		dashes=$(printf '%*s' "$dash_count" | tr ' ' '-')
		if [ "$flg_use_quiet_mode" == "false" ]; then
			echo -e "$scenario_name $scenario_desc response:\n$(echo "$response" | jq)"
		else
			echo "$scenario_name $scenario_desc $dashes Status code: $(print_status_code "$response")"
		fi
	fi



	scenario_number="14"
	scenario_name="Scenario $scenario_number"
	scenario_desc="(item description: null)"
	if [[ ("$flg_all" == "true" || " ${scenarios_to_run[@]} " =~ " $scenario_number ") && ! " ${scenarios_to_exclude[@]} " =~ " $scenario_number " ]]; then
		# Scenario 14 (item description: null)
		request_data=$(cat <<-EOF
			{
				"originAddress": {
					"postalCode": "60010",
					"addressLines": [],
					"city": "BARRINGTON $scenario_name",
					"state": "IL",
					"country": "US"
				},
				"destinationAddress": {
					"postalCode": "90210",
					"addressLines": [],
					"city": "BEVERLY HILLS $scenario_name",
					"state": "CA",
					"country": "US"
				},
				"lineItems": [
					{
						"totalWeight": "100",
						"packageDimensions": {
							"length": "12",
							"width": "12",
							"height": "12"
						},
						"packageType": "PLT",
						"totalPackages": 1,
						"totalPieces": 1,
						"freightClass": "50",
						"description": null
					}
				],
				"capacityProviderAccountGroup": {
					"code": "$account_group",
					"accounts": [
						{
							"code": "$scac"
						}
					]
				},
				"accessorialServices": [],
				"pickupWindow": {
						"date": "$(date -d 'tomorrow' +'%Y-%m-%d')",
						"startTime": "$(date -d 'tomorrow' +'%H:%M')",
						"endTime": "$(date -d 'tomorrow 6 hours' +'%H:%M')"
				},
				"deliveryWindow":{
					"date": "$(date -d '2 days' +'%Y-%m-%d')",
					"startTime": "$(date -d '2 days 3 hours' +'%H:%M')",
					"endTime": "$(date -d '2 days 6 hours' +'%H:%M')"
				},
				"preferredCurrency": "USD",
				"totalLinearFeet": null,
				"linearFeetVisualizationIdentifier": null,
				"weightUnit": "LB",
				"lengthUnit": "IN",
				"apiConfiguration": {
					"enableUnitConversion": true,
					"accessorialServiceConfiguration": {
						"fetchAllServiceLevels": true,
						"allowUnacceptedAccessorials": false
					}
				}
			}
		EOF
		)

		curl_call=$(cat <<-EOF
			$curl_template '$request_data'
		EOF
		)
		
		if [ "$flg_generate_output" == "true" ]; then
			echo "$curl_call" > "$(pwd)/$output_folder/${curl_call_scenario_file_prefix}_$scenario_number.txt"
		fi
		response=$(eval "$curl_call" | jq)
		dash_count=$(($total_status_output_length - ${#scenario_name} - ${#scenario_desc} - 1))
		dashes=$(printf '%*s' "$dash_count" | tr ' ' '-')
		if [ "$flg_use_quiet_mode" == "false" ]; then
			echo -e "$scenario_name $scenario_desc response:\n$(echo "$response" | jq)"
		else
			echo "$scenario_name $scenario_desc $dashes Status code: $(print_status_code "$response")"
		fi
	fi





	scenario_number="15-1"
	scenario_name="Scenario $scenario_number"
	scenario_desc="(payment terms: SHIPPER/PREPAID)"
	if [[ ("$flg_all" == "true" || " ${scenarios_to_run[@]} " =~ " $scenario_number ") && ! " ${scenarios_to_exclude[@]} " =~ " $scenario_number " ]]; then
		# Scenario 15-1 (payment terms: SHIPPER/PREPAID)
		request_data=$(cat <<-EOF
			{
				"directionOverride": "SHIPPER",
				"paymentTermsOverride": "PREPAID",
				"originAddress": {
					"postalCode": "60010",
					"addressLines": [],
					"city": "BARRINGTON $scenario_name",
					"state": "IL",
					"country": "US"
				},
				"destinationAddress": {
					"postalCode": "90210",
					"addressLines": [],
					"city": "BEVERLY HILLS $scenario_name",
					"state": "CA",
					"country": "US"
				},
				"lineItems": [
					{
						"totalWeight": "100",
						"packageDimensions": {
							"length": "12",
							"width": "12",
							"height": "12"
						},
						"packageType": "PLT",
						"totalPackages": 1,
						"totalPieces": 1,
						"freightClass": "50",
						"description": "$scenario_name"
					}
				],
				"capacityProviderAccountGroup": {
					"code": "$account_group",
					"accounts": [
						{
							"code": "$scac"
						}
					]
				},
				"accessorialServices": [],
				"pickupWindow": {
						"date": "$(date -d 'tomorrow' +'%Y-%m-%d')",
						"startTime": "$(date -d 'tomorrow' +'%H:%M')",
						"endTime": "$(date -d 'tomorrow 6 hours' +'%H:%M')"
				},
				"deliveryWindow":{
					"date": "$(date -d '2 days' +'%Y-%m-%d')",
					"startTime": "$(date -d '2 days 3 hours' +'%H:%M')",
					"endTime": "$(date -d '2 days 6 hours' +'%H:%M')"
				},
				"preferredCurrency": "USD",
				"totalLinearFeet": null,
				"linearFeetVisualizationIdentifier": null,
				"weightUnit": "LB",
				"lengthUnit": "IN",
				"apiConfiguration": {
					"enableUnitConversion": true,
					"accessorialServiceConfiguration": {
						"fetchAllServiceLevels": true,
						"allowUnacceptedAccessorials": false
					}
				}
			}
		EOF
		)

		curl_call=$(cat <<-EOF
			$curl_template '$request_data'
		EOF
		)
		
		if [ "$flg_generate_output" == "true" ]; then
			echo "$curl_call" > "$(pwd)/$output_folder/${curl_call_scenario_file_prefix}_$scenario_number.txt"
		fi
		response=$(eval "$curl_call" | jq)
		dash_count=$(($total_status_output_length - ${#scenario_name} - ${#scenario_desc} - 1))
		dashes=$(printf '%*s' "$dash_count" | tr ' ' '-')
		if [ "$flg_use_quiet_mode" == "false" ]; then
			echo -e "$scenario_name $scenario_desc response:\n$(echo "$response" | jq)"
		else
			echo "$scenario_name $scenario_desc $dashes Status code: $(print_status_code "$response")"
		fi
	fi



	scenario_number="15-2"
	scenario_name="Scenario $scenario_number"
	scenario_desc="(payment terms: CONSIGNEE/COLLECT)"
	if [[ ("$flg_all" == "true" || " ${scenarios_to_run[@]} " =~ " $scenario_number ") && ! " ${scenarios_to_exclude[@]} " =~ " $scenario_number " ]]; then
		# Scenario 15-2 (payment terms: CONSIGNEE/COLLECT)
		request_data=$(cat <<-EOF
			{
				"directionOverride": "CONSIGNEE",
				"paymentTermsOverride": "COLLECT",
				"originAddress": {
					"postalCode": "60010",
					"addressLines": [],
					"city": "BARRINGTON $scenario_name",
					"state": "IL",
					"country": "US"
				},
				"destinationAddress": {
					"postalCode": "90210",
					"addressLines": [],
					"city": "BEVERLY HILLS $scenario_name",
					"state": "CA",
					"country": "US"
				},
				"lineItems": [
					{
						"totalWeight": "100",
						"packageDimensions": {
							"length": "12",
							"width": "12",
							"height": "12"
						},
						"packageType": "PLT",
						"totalPackages": 1,
						"totalPieces": 1,
						"freightClass": "50",
						"description": "$scenario_name"
					}
				],
				"capacityProviderAccountGroup": {
					"code": "$account_group",
					"accounts": [
						{
							"code": "$scac"
						}
					]
				},
				"accessorialServices": [],
				"pickupWindow": {
						"date": "$(date -d 'tomorrow' +'%Y-%m-%d')",
						"startTime": "$(date -d 'tomorrow' +'%H:%M')",
						"endTime": "$(date -d 'tomorrow 6 hours' +'%H:%M')"
				},
				"deliveryWindow":{
					"date": "$(date -d '2 days' +'%Y-%m-%d')",
					"startTime": "$(date -d '2 days 3 hours' +'%H:%M')",
					"endTime": "$(date -d '2 days 6 hours' +'%H:%M')"
				},
				"preferredCurrency": "USD",
				"totalLinearFeet": null,
				"linearFeetVisualizationIdentifier": null,
				"weightUnit": "LB",
				"lengthUnit": "IN",
				"apiConfiguration": {
					"enableUnitConversion": true,
					"accessorialServiceConfiguration": {
						"fetchAllServiceLevels": true,
						"allowUnacceptedAccessorials": false
					}
				}
			}
		EOF
		)

		curl_call=$(cat <<-EOF
			$curl_template '$request_data'
		EOF
		)
		
		if [ "$flg_generate_output" == "true" ]; then
			echo "$curl_call" > "$(pwd)/$output_folder/${curl_call_scenario_file_prefix}_$scenario_number.txt"
		fi
		response=$(eval "$curl_call" | jq)
		dash_count=$(($total_status_output_length - ${#scenario_name} - ${#scenario_desc} - 1))
		dashes=$(printf '%*s' "$dash_count" | tr ' ' '-')
		if [ "$flg_use_quiet_mode" == "false" ]; then
			echo -e "$scenario_name $scenario_desc response:\n$(echo "$response" | jq)"
		else
			echo "$scenario_name $scenario_desc $dashes Status code: $(print_status_code "$response")"
		fi
	fi



	scenario_number="16-1"
	scenario_name="Scenario $scenario_number"
	scenario_desc="(pickup date: past)"
	if [[ ("$flg_all" == "true" || " ${scenarios_to_run[@]} " =~ " $scenario_number ") && ! " ${scenarios_to_exclude[@]} " =~ " $scenario_number " ]]; then
		# Scenario 16-1 (pickup date: past)
		request_data=$(cat <<-EOF
			{
				"originAddress": {
					"postalCode": "60010",
					"addressLines": [],
					"city": "BARRINGTON $scenario_name",
					"state": "IL",
					"country": "US"
				},
				"destinationAddress": {
					"postalCode": "90210",
					"addressLines": [],
					"city": "BEVERLY HILLS $scenario_name",
					"state": "CA",
					"country": "US"
				},
				"lineItems": [
					{
						"totalWeight": "100",
						"packageDimensions": {
							"length": "12",
							"width": "12",
							"height": "12"
						},
						"packageType": "PLT",
						"totalPackages": 1,
						"totalPieces": 1,
						"freightClass": "50",
						"description": "$scenario_name"
					}
				],
				"capacityProviderAccountGroup": {
					"code": "$account_group",
					"accounts": [
						{
							"code": "$scac"
						}
					]
				},
				"accessorialServices": [],
				"pickupWindow": {
					"date": "$(date -d 'yesterday' +'%Y-%m-%d')",
					"startTime": "$(date -d 'yesterday' +'%H:%M')"
				},
				"deliveryWindow":{
					"date": "$(date -d '2 days' +'%Y-%m-%d')",
					"startTime": "$(date -d '2 days 3 hours' +'%H:%M')",
					"endTime": "$(date -d '2 days 6 hours' +'%H:%M')"
				},
				"preferredCurrency": "USD",
				"totalLinearFeet": null,
				"linearFeetVisualizationIdentifier": null,
				"weightUnit": "LB",
				"lengthUnit": "IN",
				"apiConfiguration": {
					"enableUnitConversion": true,
					"accessorialServiceConfiguration": {
						"fetchAllServiceLevels": true,
						"allowUnacceptedAccessorials": false
					}
				}
			}
		EOF
		)

		curl_call=$(cat <<-EOF
			$curl_template '$request_data'
		EOF
		)
		
		if [ "$flg_generate_output" == "true" ]; then
			echo "$curl_call" > "$(pwd)/$output_folder/${curl_call_scenario_file_prefix}_$scenario_number.txt"
		fi
		response=$(eval "$curl_call" | jq)
		dash_count=$(($total_status_output_length - ${#scenario_name} - ${#scenario_desc} - 1))
		dashes=$(printf '%*s' "$dash_count" | tr ' ' '-')
		if [ "$flg_use_quiet_mode" == "false" ]; then
			echo -e "$scenario_name $scenario_desc response:\n$(echo "$response" | jq)"
		else
			echo "$scenario_name $scenario_desc $dashes Status code: $(print_status_code "$response")"
		fi
	fi


	scenario_number="16-2"
	scenario_name="Scenario $scenario_number"
	scenario_desc="(pickup date: future)"
	if [[ ("$flg_all" == "true" || " ${scenarios_to_run[@]} " =~ " $scenario_number ") && ! " ${scenarios_to_exclude[@]} " =~ " $scenario_number " ]]; then
		# Scenario 16-2 (pickup date: future)
		request_data=$(cat <<-EOF
			{
				"originAddress": {
					"postalCode": "60010",
					"addressLines": [],
					"city": "BARRINGTON $scenario_name",
					"state": "IL",
					"country": "US"
				},
				"destinationAddress": {
					"postalCode": "90210",
					"addressLines": [],
					"city": "BEVERLY HILLS $scenario_name",
					"state": "CA",
					"country": "US"
				},
				"lineItems": [
					{
						"totalWeight": "100",
						"packageDimensions": {
							"length": "12",
							"width": "12",
							"height": "12"
						},
						"packageType": "PLT",
						"totalPackages": 1,
						"totalPieces": 1,
						"freightClass": "50",
						"description": "$scenario_name"
					}
				],
				"capacityProviderAccountGroup": {
					"code": "$account_group",
					"accounts": [
						{
							"code": "$scac"
						}
					]
				},
				"accessorialServices": [],
				"pickupWindow": {
						"date": "$(date -d 'tomorrow' +'%Y-%m-%d')",
						"startTime": "$(date -d 'tomorrow' +'%H:%M')",
						"endTime": "$(date -d 'tomorrow 6 hours' +'%H:%M')"
				},
				"deliveryWindow":{
					"date": "$(date -d '2 days' +'%Y-%m-%d')",
					"startTime": "$(date -d '2 days 3 hours' +'%H:%M')",
					"endTime": "$(date -d '2 days 6 hours' +'%H:%M')"
				},
				"preferredCurrency": "USD",
				"totalLinearFeet": null,
				"linearFeetVisualizationIdentifier": null,
				"weightUnit": "LB",
				"lengthUnit": "IN",
				"apiConfiguration": {
					"enableUnitConversion": true,
					"accessorialServiceConfiguration": {
						"fetchAllServiceLevels": true,
						"allowUnacceptedAccessorials": false
					}
				}
			}
		EOF
		)

		curl_call=$(cat <<-EOF
			$curl_template '$request_data'
		EOF
		)
		
		if [ "$flg_generate_output" == "true" ]; then
			echo "$curl_call" > "$(pwd)/$output_folder/${curl_call_scenario_file_prefix}_$scenario_number.txt"
		fi
		response=$(eval "$curl_call" | jq)
		dash_count=$(($total_status_output_length - ${#scenario_name} - ${#scenario_desc} - 1))
		dashes=$(printf '%*s' "$dash_count" | tr ' ' '-')
		if [ "$flg_use_quiet_mode" == "false" ]; then
			echo -e "$scenario_name $scenario_desc response:\n$(echo "$response" | jq)"
		else
			echo "$scenario_name $scenario_desc $dashes Status code: $(print_status_code "$response")"
		fi
	fi


	scenario_number="17"
	scenario_name="Scenario $scenario_number"
	scenario_desc="(zip codes valid: 90210 to 10001)"
	if [[ ("$flg_all" == "true" || " ${scenarios_to_run[@]} " =~ " $scenario_number ") && ! " ${scenarios_to_exclude[@]} " =~ " $scenario_number " ]]; then
		# Scenario 17 (zip codes valid: 90210 to 10001)
		request_data=$(cat <<-EOF
			{
				"originAddress": {
					"postalCode": "90211",
					"addressLines": [],
					"city": "BARRINGTON $scenario_name",
					"state": "IL",
					"country": "US"
				},
				"destinationAddress": {
					"postalCode": "10000",
					"addressLines": [],
					"city": "BEVERLY HILLS $scenario_name",
					"state": "CA",
					"country": "US"
				},
				"lineItems": [
					{
						"totalWeight": "100",
						"packageDimensions": {
							"length": "12",
							"width": "12",
							"height": "12"
						},
						"packageType": "PLT",
						"totalPackages": 1,
						"totalPieces": 1,
						"freightClass": "50",
						"description": "$scenario_name"
					}
				],
				"capacityProviderAccountGroup": {
					"code": "$account_group",
					"accounts": [
						{
							"code": "$scac"
						}
					]
				},
				"accessorialServices": [],
				"pickupWindow": {
						"date": "$(date -d 'tomorrow' +'%Y-%m-%d')",
						"startTime": "$(date -d 'tomorrow' +'%H:%M')",
						"endTime": "$(date -d 'tomorrow 6 hours' +'%H:%M')"
				},
				"deliveryWindow":{
					"date": "$(date -d '2 days' +'%Y-%m-%d')",
					"startTime": "$(date -d '2 days 3 hours' +'%H:%M')",
					"endTime": "$(date -d '2 days 6 hours' +'%H:%M')"
				},
				"preferredCurrency": "USD",
				"totalLinearFeet": null,
				"linearFeetVisualizationIdentifier": null,
				"weightUnit": "LB",
				"lengthUnit": "IN",
				"apiConfiguration": {
					"enableUnitConversion": true,
					"accessorialServiceConfiguration": {
						"fetchAllServiceLevels": true,
						"allowUnacceptedAccessorials": false
					}
				}
			}
		EOF
		)

		curl_call=$(cat <<-EOF
			$curl_template '$request_data'
		EOF
		)
		
		if [ "$flg_generate_output" == "true" ]; then
			echo "$curl_call" > "$(pwd)/$output_folder/${curl_call_scenario_file_prefix}_$scenario_number.txt"
		fi
		response=$(eval "$curl_call" | jq)
		dash_count=$(($total_status_output_length - ${#scenario_name} - ${#scenario_desc} - 1))
		dashes=$(printf '%*s' "$dash_count" | tr ' ' '-')
		if [ "$flg_use_quiet_mode" == "false" ]; then
			echo -e "$scenario_name $scenario_desc response:\n$(echo "$response" | jq)"
		else
			echo "$scenario_name $scenario_desc $dashes Status code: $(print_status_code "$response")"
		fi
	fi


	scenario_number="18-1"
	scenario_name="Scenario $scenario_number"
	scenario_desc="(weight: 20000)"
	if [[ ("$flg_all" == "true" || " ${scenarios_to_run[@]} " =~ " $scenario_number ") && ! " ${scenarios_to_exclude[@]} " =~ " $scenario_number " ]]; then
		# Scenario 18-1 (weight: 20000)
		request_data=$(cat <<-EOF
			{
				"originAddress": {
					"postalCode": "60010",
					"addressLines": [],
					"city": "BARRINGTON $scenario_name",
					"state": "IL",
					"country": "US"
				},
				"destinationAddress": {
					"postalCode": "90210",
					"addressLines": [],
					"city": "BEVERLY HILLS $scenario_name",
					"state": "CA",
					"country": "US"
				},
				"lineItems": [
					{
						"totalWeight": "20000",
						"packageDimensions": {
							"length": "12",
							"width": "12",
							"height": "12"
						},
						"packageType": "PLT",
						"totalPackages": 1,
						"totalPieces": 1,
						"freightClass": "50",
						"description": "$scenario_name"
					}
				],
				"capacityProviderAccountGroup": {
					"code": "$account_group",
					"accounts": [
						{
							"code": "$scac"
						}
					]
				},
				"accessorialServices": [],
				"pickupWindow": {
						"date": "$(date -d 'tomorrow' +'%Y-%m-%d')",
						"startTime": "$(date -d 'tomorrow' +'%H:%M')",
						"endTime": "$(date -d 'tomorrow 6 hours' +'%H:%M')"
				},
				"deliveryWindow":{
					"date": "$(date -d '2 days' +'%Y-%m-%d')",
					"startTime": "$(date -d '2 days 3 hours' +'%H:%M')",
					"endTime": "$(date -d '2 days 6 hours' +'%H:%M')"
				},
				"preferredCurrency": "USD",
				"totalLinearFeet": null,
				"linearFeetVisualizationIdentifier": null,
				"weightUnit": "LB",
				"lengthUnit": "IN",
				"apiConfiguration": {
					"enableUnitConversion": true,
					"accessorialServiceConfiguration": {
						"fetchAllServiceLevels": true,
						"allowUnacceptedAccessorials": false
					}
				}
			}
		EOF
		)

		curl_call=$(cat <<-EOF
			$curl_template '$request_data'
		EOF
		)
		
		if [ "$flg_generate_output" == "true" ]; then
			echo "$curl_call" > "$(pwd)/$output_folder/${curl_call_scenario_file_prefix}_$scenario_number.txt"
		fi
		response=$(eval "$curl_call" | jq)
		dash_count=$(($total_status_output_length - ${#scenario_name} - ${#scenario_desc} - 1))
		dashes=$(printf '%*s' "$dash_count" | tr ' ' '-')
		if [ "$flg_use_quiet_mode" == "false" ]; then
			echo -e "$scenario_name $scenario_desc response:\n$(echo "$response" | jq)"
		else
			echo "$scenario_name $scenario_desc $dashes Status code: $(print_status_code "$response")"
		fi
	fi


	scenario_number="18-2"
	scenario_name="Scenario $scenario_number"
	scenario_desc="(dimensions: 29 ft)"
	if [[ ("$flg_all" == "true" || " ${scenarios_to_run[@]} " =~ " $scenario_number ") && ! " ${scenarios_to_exclude[@]} " =~ " $scenario_number " ]]; then
		# Scenario 18-2 (dimensions: 29 ft)
		request_data=$(cat <<-EOF
			{
				"originAddress": {
					"postalCode": "60010",
					"addressLines": [],
					"city": "BARRINGTON $scenario_name",
					"state": "IL",
					"country": "US"
				},
				"destinationAddress": {
					"postalCode": "90210",
					"addressLines": [],
					"city": "BEVERLY HILLS $scenario_name",
					"state": "CA",
					"country": "US"
				},
				"lineItems": [
					{
						"totalWeight": "100",
						"packageDimensions": {
							"length": "29",
							"width": "29",
							"height": "29"
						},
						"packageType": "PLT",
						"totalPackages": 1,
						"totalPieces": 1,
						"freightClass": "50",
						"description": "$scenario_name"
					}
				],
				"capacityProviderAccountGroup": {
					"code": "$account_group",
					"accounts": [
						{
							"code": "$scac"
						}
					]
				},
				"accessorialServices": [],
				"pickupWindow": {
						"date": "$(date -d 'tomorrow' +'%Y-%m-%d')",
						"startTime": "$(date -d 'tomorrow' +'%H:%M')",
						"endTime": "$(date -d 'tomorrow 6 hours' +'%H:%M')"
				},
				"deliveryWindow":{
					"date": "$(date -d '2 days' +'%Y-%m-%d')",
					"startTime": "$(date -d '2 days 3 hours' +'%H:%M')",
					"endTime": "$(date -d '2 days 6 hours' +'%H:%M')"
				},
				"preferredCurrency": "USD",
				"totalLinearFeet": null,
				"linearFeetVisualizationIdentifier": null,
				"weightUnit": "LB",
				"lengthUnit": "FT",
				"apiConfiguration": {
					"enableUnitConversion": true,
					"accessorialServiceConfiguration": {
						"fetchAllServiceLevels": true,
						"allowUnacceptedAccessorials": false
					}
				}
			}
		EOF
		)

		curl_call=$(cat <<-EOF
			$curl_template '$request_data'
		EOF
		)
		
		if [ "$flg_generate_output" == "true" ]; then	
			echo "$curl_call" > "$(pwd)/$output_folder/${curl_call_scenario_file_prefix}_$scenario_number.txt"
		fi
		response=$(eval "$curl_call" | jq)
		dash_count=$(($total_status_output_length - ${#scenario_name} - ${#scenario_desc} - 1))
		dashes=$(printf '%*s' "$dash_count" | tr ' ' '-')
		if [ "$flg_use_quiet_mode" == "false" ]; then
			echo -e "$scenario_name $scenario_desc response:\n$(echo "$response" | jq)"
		else
			echo "$scenario_name $scenario_desc $dashes Status code: $(print_status_code "$response")"
		fi
	fi


	# Create helper doc
	if [ "$flg_generate_output" == "true" ]; then
		grep -R -E 'type|value' "$output_folder/${curl_call_scenario_file_prefix}"* >> "$output_folder/$helper_doc_file_name"
		grep -R -E 'startDate|endDate' "$output_folder/${curl_call_scenario_file_prefix}"* >> "$output_folder/$helper_doc_file_name"
	fi

	echo "Logs: $logs_url"
fi
# End of: run rating












# Start of: run dispatch
if [ "$flg_run_dispatch" == "true" ]; then

	# Set up logs
	logs_url="https://140271604703.observeinc.com/workspace/41124764/log-explorer?datasetId=41414971&time-preset=PAST_15_MINUTES&fv=41425674&s=21846-1oa7lvej"

	# Set up output folder
	if [ "$flg_generate_output" == "true" ]; then
		output_folder="curl_calls_${scac}_dispatch_$(date +'%Y-%m-%d_%H-%M-%S')"
		if [ -d "$output_folder" ]; then
			rm -r "$output_folder"
			mkdir "$output_folder"
		else
			mkdir "$output_folder"
		fi
	fi

	curl_template=$(cat <<-EOF
	    curl $curl_opts --location 'https://na12.api.qa-integration.p-44.com/api/v4/ltl/dispatchedshipments' \
	        --header "Authorization: Bearer $token" \
	        --header "Content-Type: application/json" \
	        --data
	EOF
	)




	scenario_number="01-1"
	scenario_name="Scenario $scenario_number"
	scenario_desc="(payment terms: SHIPPER/PREPAID)"
	if [[ ("$flg_all" == "true" || " ${scenarios_to_run[@]} " =~ " $scenario_number ") && ! " ${scenarios_to_exclude[@]} " =~ " $scenario_number " ]]; then

		request_data=$(cat <<-EOF
		{
			"weightUnit": "LB",
			"lengthUnit": "IN",
			"paymentTermsOverride": "PREPAID",
			"directionOverride": "SHIPPER",
			"capacityProviderAccountGroup": {
				"code": "$account_group",
				"accounts": [
					{
						"code": "$scac"
					}
				]
			},
			"originLocation": {
				"address": {
					"country": "CA",
					"postalCode": "N0B1X0",
					"addressLines": [
						"1270 Geddes St"
					],
					"city": "Hawkesville $scenario_name",
					"state": "ON"
				},
				"contact": {
					"companyName": "A M I ATTACHMENTS INC",
					"contactName": "Darlene Ward",
					"phoneNumber": "5196993923",
					"email": "darlene.w@amiattachments.com"
				}
			},
			"destinationLocation": {
				"address": {
					"country": "CA",
					"postalCode": "T5M 2S1",
					"addressLines": [
						"16116  -111 Avenue Northwest"
					],
					"city": "Edmonton $scenario_name",
					"state": "AB"
				},
				"contact": {
					"companyName": "SMS Equipment Inc.",
					"contactName": "AARON RYAN",
					"phoneNumber": "7804512630"
				}
			},
			"requesterLocation": {
				"address": {
					"country": "CA",
					"postalCode": "N0B1X0",
					"addressLines": [
						"1270 Geddes St"
					],
					"city": "Hawkesville $scenario_name",
					"state": "ON"
				},
				"contact": {
					"companyName": "A M I ATTACHMENTS INC",
					"contactName": "Darlene Ward",
					"phoneNumber": "5196993923",
					"email": "darlene.w@amiattachments.com"
				}
			},
			"lineItems": [
				{
					"freightClass": "70",
					"packageType": "PLT",
					"totalWeight": 180.0,
					"packageDimensions": {
						"length": 24.0,
						"width": 24.0,
						"height": 12.0
					},
					"totalPackages": 1,
					"totalPieces": 1,
					"description": "$scenario_name",
					"stackable": false
				}
			],
			"pickupWindow": {
				"date": "$(date -d 'tomorrow' +'%Y-%m-%d')",
				"startTime": "$(date -d 'tomorrow' +'%H:%M')",
				"endTime": "$(date -d 'tomorrow 6 hours' +'%H:%M')"
			},
			"deliveryWindow": {
				"date": "$(date -d '2 days' +'%Y-%m-%d')",
				"startTime": "$(date -d '2 days' +'%H:%M')",
				"endTime": "$(date -d '2 days 6 hours' +'%H:%M')"
			},
			"carrierCode": "$scac",
			"shipmentIdentifiers": [
				{
					"type": "CUSTOMER_REFERENCE",
					"value": "{$scac}_dispatch_test_{$scenario_number}_$(date +%s)"
				},
				{
					"type": "PURCHASE_ORDER",
					"value": "{$scac}_dispatch_test_{$scenario_number}_$(date +%s)"
				}
			],
			"accessorialServices": [],
			"pickupNote": "TOTAL 1 H/U",
			"emergencyContact": {},
			"capacityProviderQuoteNumber": "{$scac}_{$scenario_number}_$(date +%s)",
			"apiConfiguration": {
				"noteConfiguration": {
					"enableTruncation": true
				},
				"allowUnsupportedAccessorials": true,
				"pickupOnly": false
			}
		}
		EOF
		)
		curl_call=$(cat <<-EOF
			$curl_template '$request_data'
		EOF
		)
		
		if [ "$flg_generate_output" == "true" ]; then	
			echo "$curl_call" > "$(pwd)/$output_folder/${curl_call_scenario_file_prefix}_$scenario_number.txt"
		fi
		response=$(eval "$curl_call" | jq)
		dash_count=$(($total_status_output_length - ${#scenario_name} - ${#scenario_desc} - 1))
		dashes=$(printf '%*s' "$dash_count" | tr ' ' '-')
		if [ "$flg_use_quiet_mode" == "false" ]; then
			echo -e "$scenario_name $scenario_desc response:\n$(echo "$response" | jq)"
		else
			echo "$scenario_name $scenario_desc $dashes Status code: $(print_status_code "$response")"
		fi
	fi


	scenario_number="01-2"
	scenario_name="Scenario $scenario_number"
	scenario_desc="(payment terms: CONSIGNEE/COLLECT)"
	if [[ ("$flg_all" == "true" || " ${scenarios_to_run[@]} " =~ " $scenario_number ") && ! " ${scenarios_to_exclude[@]} " =~ " $scenario_number " ]]; then
	
		request_data=$(cat <<-EOF
		{
			"weightUnit": "LB",
			"lengthUnit": "IN",
			"paymentTermsOverride": "COLLECT",
			"directionOverride": "CONSIGNEE",
			"capacityProviderAccountGroup": {
				"code": "$account_group",
				"accounts": [
					{
						"code": "$scac"
					}
				]
			},
			"originLocation": {
				"address": {
					"country": "CA",
					"postalCode": "N0B1X0",
					"addressLines": [
						"1270 Geddes St"
					],
					"city": "Hawkesville $scenario_name",
					"state": "ON"
				},
				"contact": {
					"companyName": "A M I ATTACHMENTS INC",
					"contactName": "Darlene Ward",
					"phoneNumber": "5196993923",
					"email": "darlene.w@amiattachments.com"
				}
			},
			"destinationLocation": {
				"address": {
					"country": "CA",
					"postalCode": "T5M 2S1",
					"addressLines": [
						"16116  -111 Avenue Northwest"
					],
					"city": "Edmonton $scenario_name",
					"state": "AB"
				},
				"contact": {
					"companyName": "SMS Equipment Inc.",
					"contactName": "AARON RYAN",
					"phoneNumber": "7804512630"
				}
			},
			"requesterLocation": {
				"address": {
					"country": "CA",
					"postalCode": "N0B1X0",
					"addressLines": [
						"1270 Geddes St"
					],
					"city": "Hawkesville $scenario_name",
					"state": "ON"
				},
				"contact": {
					"companyName": "A M I ATTACHMENTS INC",
					"contactName": "Darlene Ward",
					"phoneNumber": "5196993923",
					"email": "darlene.w@amiattachments.com"
				}
			},
			"lineItems": [
				{
					"freightClass": "70",
					"packageType": "PLT",
					"totalWeight": 180.0,
					"packageDimensions": {
						"length": 24.0,
						"width": 24.0,
						"height": 12.0
					},
					"totalPackages": 1,
					"totalPieces": 1,
					"description": "$scenario_name",
					"stackable": false
				}
			],
			"pickupWindow": {
				"date": "$(date -d 'tomorrow' +'%Y-%m-%d')",
				"startTime": "$(date -d 'tomorrow' +'%H:%M')",
				"endTime": "$(date -d 'tomorrow 6 hours' +'%H:%M')"
			},
			"deliveryWindow": {
				"date": "$(date -d '2 days' +'%Y-%m-%d')",
				"startTime": "$(date -d '2 days' +'%H:%M')",
				"endTime": "$(date -d '2 days 6 hours' +'%H:%M')"
			},
			"carrierCode": "$scac",
			"shipmentIdentifiers": [
				{
					"type": "CUSTOMER_REFERENCE",
					"value": "{$scac}_dispatch_test_{$scenario_number}_$(date +%s)"
				},
				{
					"type": "PURCHASE_ORDER",
					"value": "{$scac}_dispatch_test_{$scenario_number}_$(date +%s)"
				}
			],
			"accessorialServices": [],
			"pickupNote": "TOTAL 1 H/U",
			"emergencyContact": {},
			"capacityProviderQuoteNumber": "{$scac}_{$scenario_number}_$(date +%s)",
			"apiConfiguration": {
				"noteConfiguration": {
					"enableTruncation": true
				},
				"allowUnsupportedAccessorials": true,
				"pickupOnly": false
			}
		}
		EOF
		)
		curl_call=$(cat <<-EOF
			$curl_template '$request_data'
		EOF
		)
		
		if [ "$flg_generate_output" == "true" ]; then	
			echo "$curl_call" > "$(pwd)/$output_folder/${curl_call_scenario_file_prefix}_$scenario_number.txt"
		fi
		response=$(eval "$curl_call" | jq)
		dash_count=$(($total_status_output_length - ${#scenario_name} - ${#scenario_desc} - 1))
		dashes=$(printf '%*s' "$dash_count" | tr ' ' '-')
		if [ "$flg_use_quiet_mode" == "false" ]; then
			echo -e "$scenario_name $scenario_desc response:\n$(echo "$response" | jq)"
		else
			echo "$scenario_name $scenario_desc $dashes Status code: $(print_status_code "$response")"
		fi
	fi


	scenario_number="01-3"
	scenario_name="Scenario $scenario_number"
	scenario_desc="(payment terms: PREPAID/THIRD_PARTY)"
	if [[ ("$flg_all" == "true" || " ${scenarios_to_run[@]} " =~ " $scenario_number ") && ! " ${scenarios_to_exclude[@]} " =~ " $scenario_number " ]]; then
	
		request_data=$(cat <<-EOF
		{
			"weightUnit": "LB",
			"lengthUnit": "IN",
			"paymentTermsOverride": "PREPAID",
			"directionOverride": "THIRD_PARTY",
			"capacityProviderAccountGroup": {
				"code": "$account_group",
				"accounts": [
					{
						"code": "$scac"
					}
				]
			},
			"originLocation": {
				"address": {
					"country": "CA",
					"postalCode": "N0B1X0",
					"addressLines": [
						"1270 Geddes St"
					],
					"city": "Hawkesville $scenario_name",
					"state": "ON"
				},
				"contact": {
					"companyName": "A M I ATTACHMENTS INC",
					"contactName": "Darlene Ward",
					"phoneNumber": "5196993923",
					"email": "darlene.w@amiattachments.com"
				}
			},
			"destinationLocation": {
				"address": {
					"country": "CA",
					"postalCode": "T5M 2S1",
					"addressLines": [
						"16116  -111 Avenue Northwest"
					],
					"city": "Edmonton $scenario_name",
					"state": "AB"
				},
				"contact": {
					"companyName": "SMS Equipment Inc.",
					"contactName": "AARON RYAN",
					"phoneNumber": "7804512630"
				}
			},
			"requesterLocation": {
				"address": {
					"country": "CA",
					"postalCode": "N0B1X0",
					"addressLines": [
						"1270 Geddes St"
					],
					"city": "Hawkesville $scenario_name",
					"state": "ON"
				},
				"contact": {
					"companyName": "A M I ATTACHMENTS INC",
					"contactName": "Darlene Ward",
					"phoneNumber": "5196993923",
					"email": "darlene.w@amiattachments.com"
				}
			},
			"lineItems": [
				{
					"freightClass": "70",
					"packageType": "PLT",
					"totalWeight": 180.0,
					"packageDimensions": {
						"length": 24.0,
						"width": 24.0,
						"height": 12.0
					},
					"totalPackages": 1,
					"totalPieces": 1,
					"description": "$scenario_name",
					"stackable": false
				}
			],
			"pickupWindow": {
				"date": "$(date -d 'tomorrow' +'%Y-%m-%d')",
				"startTime": "$(date -d 'tomorrow' +'%H:%M')",
				"endTime": "$(date -d 'tomorrow 6 hours' +'%H:%M')"
			},
			"deliveryWindow": {
				"date": "$(date -d '2 days' +'%Y-%m-%d')",
				"startTime": "$(date -d '2 days' +'%H:%M')",
				"endTime": "$(date -d '2 days 6 hours' +'%H:%M')"
			},
			"carrierCode": "$scac",
			"shipmentIdentifiers": [
				{
					"type": "CUSTOMER_REFERENCE",
					"value": "{$scac}_dispatch_test_{$scenario_number}_$(date +%s)"
				},
				{
					"type": "PURCHASE_ORDER",
					"value": "{$scac}_dispatch_test_{$scenario_number}_$(date +%s)"
				}
			],
			"accessorialServices": [],
			"pickupNote": "TOTAL 1 H/U",
			"emergencyContact": {},
			"capacityProviderQuoteNumber": "{$scac}_{$scenario_number}_$(date +%s)",
			"apiConfiguration": {
				"noteConfiguration": {
					"enableTruncation": true
				},
				"allowUnsupportedAccessorials": true,
				"pickupOnly": false
			}
		}
		EOF
		)
		curl_call=$(cat <<-EOF
			$curl_template '$request_data'
		EOF
		)
		
		if [ "$flg_generate_output" == "true" ]; then	
			echo "$curl_call" > "$(pwd)/$output_folder/${curl_call_scenario_file_prefix}_$scenario_number.txt"
		fi
		response=$(eval "$curl_call" | jq)
		dash_count=$(($total_status_output_length - ${#scenario_name} - ${#scenario_desc} - 1))
		dashes=$(printf '%*s' "$dash_count" | tr ' ' '-')
		if [ "$flg_use_quiet_mode" == "false" ]; then
			echo -e "$scenario_name $scenario_desc response:\n$(echo "$response" | jq)"
		else
			echo "$scenario_name $scenario_desc $dashes Status code: $(print_status_code "$response")"
		fi
	fi

	scenario_number="02-1"
	scenario_name="Scenario $scenario_number"
	scenario_desc="(date: past)"
	if [[ ("$flg_all" == "true" || " ${scenarios_to_run[@]} " =~ " $scenario_number ") && ! " ${scenarios_to_exclude[@]} " =~ " $scenario_number " ]]; then
	
		request_data=$(cat <<-EOF
		{
			"weightUnit": "LB",
			"lengthUnit": "IN",
			"paymentTermsOverride": "PREPAID",
			"directionOverride": "SHIPPER",
			"capacityProviderAccountGroup": {
				"code": "$account_group",
				"accounts": [
					{
						"code": "$scac"
					}
				]
			},
			"originLocation": {
				"address": {
					"country": "CA",
					"postalCode": "N0B1X0",
					"addressLines": [
						"1270 Geddes St"
					],
					"city": "Hawkesville $scenario_name",
					"state": "ON"
				},
				"contact": {
					"companyName": "A M I ATTACHMENTS INC",
					"contactName": "Darlene Ward",
					"phoneNumber": "5196993923",
					"email": "darlene.w@amiattachments.com"
				}
			},
			"destinationLocation": {
				"address": {
					"country": "CA",
					"postalCode": "T5M 2S1",
					"addressLines": [
						"16116  -111 Avenue Northwest"
					],
					"city": "Edmonton $scenario_name",
					"state": "AB"
				},
				"contact": {
					"companyName": "SMS Equipment Inc.",
					"contactName": "AARON RYAN",
					"phoneNumber": "7804512630"
				}
			},
			"requesterLocation": {
				"address": {
					"country": "CA",
					"postalCode": "N0B1X0",
					"addressLines": [
						"1270 Geddes St"
					],
					"city": "Hawkesville $scenario_name",
					"state": "ON"
				},
				"contact": {
					"companyName": "A M I ATTACHMENTS INC",
					"contactName": "Darlene Ward",
					"phoneNumber": "5196993923",
					"email": "darlene.w@amiattachments.com"
				}
			},
			"lineItems": [
				{
					"freightClass": "70",
					"packageType": "PLT",
					"totalWeight": 180.0,
					"packageDimensions": {
						"length": 24.0,
						"width": 24.0,
						"height": 12.0
					},
					"totalPackages": 1,
					"totalPieces": 1,
					"description": "$scenario_name",
					"stackable": false
				}
			],
			"pickupWindow": {
				"date": "$(date -d '2 days ago' +'%Y-%m-%d')",
				"startTime": "$(date -d '2 days ago' +'%H:%M')",
				"endTime": "$(date -d '2 days ago 6 hours' +'%H:%M')"
			},
			"deliveryWindow": {
				"date": "$(date -d 'yesterday' +'%Y-%m-%d')",
				"startTime": "$(date -d 'yesterday' +'%H:%M')",
				"endTime": "$(date -d 'yesterday 6 hours' +'%H:%M')"
			},
			"carrierCode": "$scac",
			"shipmentIdentifiers": [
				{
					"type": "CUSTOMER_REFERENCE",
					"value": "{$scac}_dispatch_test_{$scenario_number}_$(date +%s)"
				},
				{
					"type": "PURCHASE_ORDER",
					"value": "{$scac}_dispatch_test_{$scenario_number}_$(date +%s)"
				}
			],
			"accessorialServices": [],
			"pickupNote": "TOTAL 1 H/U",
			"emergencyContact": {},
			"capacityProviderQuoteNumber": "{$scac}_{$scenario_number}_$(date +%s)",
			"apiConfiguration": {
				"noteConfiguration": {
					"enableTruncation": true
				},
				"allowUnsupportedAccessorials": true,
				"pickupOnly": false
			}
		}
		EOF
		)
		curl_call=$(cat <<-EOF
			$curl_template '$request_data'
		EOF
		)
		
		if [ "$flg_generate_output" == "true" ]; then	
			echo "$curl_call" > "$(pwd)/$output_folder/${curl_call_scenario_file_prefix}_$scenario_number.txt"
		fi
		response=$(eval "$curl_call" | jq)
		dash_count=$(($total_status_output_length - ${#scenario_name} - ${#scenario_desc} - 1))
		dashes=$(printf '%*s' "$dash_count" | tr ' ' '-')
		if [ "$flg_use_quiet_mode" == "false" ]; then
			echo -e "$scenario_name $scenario_desc response:\n$(echo "$response" | jq)"
		else
			echo "$scenario_name $scenario_desc $dashes Status code: $(print_status_code "$response")"
		fi
	fi

	scenario_number="02-2"
	scenario_name="Scenario $scenario_number"
	scenario_desc="(date: future)"
	if [[ ("$flg_all" == "true" || " ${scenarios_to_run[@]} " =~ " $scenario_number ") && ! " ${scenarios_to_exclude[@]} " =~ " $scenario_number " ]]; then
	
		request_data=$(cat <<-EOF
		{
			"weightUnit": "LB",
			"lengthUnit": "IN",
			"paymentTermsOverride": "PREPAID",
			"directionOverride": "SHIPPER",
			"capacityProviderAccountGroup": {
				"code": "$account_group",
				"accounts": [
					{
						"code": "$scac"
					}
				]
			},
			"originLocation": {
				"address": {
					"country": "CA",
					"postalCode": "N0B1X0",
					"addressLines": [
						"1270 Geddes St"
					],
					"city": "Hawkesville $scenario_name",
					"state": "ON"
				},
				"contact": {
					"companyName": "A M I ATTACHMENTS INC",
					"contactName": "Darlene Ward",
					"phoneNumber": "5196993923",
					"email": "darlene.w@amiattachments.com"
				}
			},
			"destinationLocation": {
				"address": {
					"country": "CA",
					"postalCode": "T5M 2S1",
					"addressLines": [
						"16116  -111 Avenue Northwest"
					],
					"city": "Edmonton $scenario_name",
					"state": "AB"
				},
				"contact": {
					"companyName": "SMS Equipment Inc.",
					"contactName": "AARON RYAN",
					"phoneNumber": "7804512630"
				}
			},
			"requesterLocation": {
				"address": {
					"country": "CA",
					"postalCode": "N0B1X0",
					"addressLines": [
						"1270 Geddes St"
					],
					"city": "Hawkesville $scenario_name",
					"state": "ON"
				},
				"contact": {
					"companyName": "A M I ATTACHMENTS INC",
					"contactName": "Darlene Ward",
					"phoneNumber": "5196993923",
					"email": "darlene.w@amiattachments.com"
				}
			},
			"lineItems": [
				{
					"freightClass": "70",
					"packageType": "PLT",
					"totalWeight": 180.0,
					"packageDimensions": {
						"length": 24.0,
						"width": 24.0,
						"height": 12.0
					},
					"totalPackages": 1,
					"totalPieces": 1,
					"description": "$scenario_name",
					"stackable": false
				}
			],
			"pickupWindow": {
				"date": "$(date -d 'tomorrow' +'%Y-%m-%d')",
				"startTime": "$(date -d 'tomorrow' +'%H:%M')",
				"endTime": "$(date -d 'tomorrow 6 hours' +'%H:%M')"
			},
			"deliveryWindow": {
				"date": "$(date -d '2 days' +'%Y-%m-%d')",
				"startTime": "$(date -d '2 days' +'%H:%M')",
				"endTime": "$(date -d '2 days 6 hours' +'%H:%M')"
			},
			"carrierCode": "$scac",
			"shipmentIdentifiers": [
				{
					"type": "CUSTOMER_REFERENCE",
					"value": "{$scac}_dispatch_test_{$scenario_number}_$(date +%s)"
				},
				{
					"type": "PURCHASE_ORDER",
					"value": "{$scac}_dispatch_test_{$scenario_number}_$(date +%s)"
				}
			],
			"accessorialServices": [],
			"pickupNote": "TOTAL 1 H/U",
			"emergencyContact": {},
			"capacityProviderQuoteNumber": "{$scac}_{$scenario_number}_$(date +%s)",
			"apiConfiguration": {
				"noteConfiguration": {
					"enableTruncation": true
				},
				"allowUnsupportedAccessorials": true,
				"pickupOnly": false
			}
		}
		EOF
		)
		curl_call=$(cat <<-EOF
			$curl_template '$request_data'
		EOF
		)
		
		if [ "$flg_generate_output" == "true" ]; then	
			echo "$curl_call" > "$(pwd)/$output_folder/${curl_call_scenario_file_prefix}_$scenario_number.txt"
		fi
		response=$(eval "$curl_call" | jq)
		dash_count=$(($total_status_output_length - ${#scenario_name} - ${#scenario_desc} - 1))
		dashes=$(printf '%*s' "$dash_count" | tr ' ' '-')
		if [ "$flg_use_quiet_mode" == "false" ]; then
			echo -e "$scenario_name $scenario_desc response:\n$(echo "$response" | jq)"
		else
			echo "$scenario_name $scenario_desc $dashes Status code: $(print_status_code "$response")"
		fi
	fi


	scenario_number="02-3"
	scenario_name="Scenario $scenario_number"
	scenario_desc="(date: same day)"
	if [[ ("$flg_all" == "true" || " ${scenarios_to_run[@]} " =~ " $scenario_number ") && ! " ${scenarios_to_exclude[@]} " =~ " $scenario_number " ]]; then
	
		request_data=$(cat <<-EOF
		{
			"weightUnit": "LB",
			"lengthUnit": "IN",
			"paymentTermsOverride": "PREPAID",
			"directionOverride": "SHIPPER",
			"capacityProviderAccountGroup": {
				"code": "$account_group",
				"accounts": [
					{
						"code": "$scac"
					}
				]
			},
			"originLocation": {
				"address": {
					"country": "CA",
					"postalCode": "N0B1X0",
					"addressLines": [
						"1270 Geddes St"
					],
					"city": "Hawkesville $scenario_name",
					"state": "ON"
				},
				"contact": {
					"companyName": "A M I ATTACHMENTS INC",
					"contactName": "Darlene Ward",
					"phoneNumber": "5196993923",
					"email": "darlene.w@amiattachments.com"
				}
			},
			"destinationLocation": {
				"address": {
					"country": "CA",
					"postalCode": "T5M 2S1",
					"addressLines": [
						"16116  -111 Avenue Northwest"
					],
					"city": "Edmonton $scenario_name",
					"state": "AB"
				},
				"contact": {
					"companyName": "SMS Equipment Inc.",
					"contactName": "AARON RYAN",
					"phoneNumber": "7804512630"
				}
			},
			"requesterLocation": {
				"address": {
					"country": "CA",
					"postalCode": "N0B1X0",
					"addressLines": [
						"1270 Geddes St"
					],
					"city": "Hawkesville $scenario_name",
					"state": "ON"
				},
				"contact": {
					"companyName": "A M I ATTACHMENTS INC",
					"contactName": "Darlene Ward",
					"phoneNumber": "5196993923",
					"email": "darlene.w@amiattachments.com"
				}
			},
			"lineItems": [
				{
					"freightClass": "70",
					"packageType": "PLT",
					"totalWeight": 180.0,
					"packageDimensions": {
						"length": 24.0,
						"width": 24.0,
						"height": 12.0
					},
					"totalPackages": 1,
					"totalPieces": 1,
					"description": "$scenario_name",
					"stackable": false
				}
			],
			"pickupWindow": {
				"date": "$(date -d 'today' +'%Y-%m-%d')",
				"startTime": "$(date -d 'today' +'%H:%M')",
				"endTime": "$(date -d 'today 2 hours' +'%H:%M')"
			},
			"deliveryWindow": {
				"date": "$(date -d 'today 3 hours' +'%Y-%m-%d')",
				"startTime": "$(date -d 'today 3 hours' +'%H:%M')",
				"endTime": "$(date -d 'today 6 hours' +'%H:%M')"
			},
			"carrierCode": "$scac",
			"shipmentIdentifiers": [
				{
					"type": "CUSTOMER_REFERENCE",
					"value": "{$scac}_dispatch_test_{$scenario_number}_$(date +%s)"
				},
				{
					"type": "PURCHASE_ORDER",
					"value": "{$scac}_dispatch_test_{$scenario_number}_$(date +%s)"
				}
			],
			"accessorialServices": [],
			"pickupNote": "TOTAL 1 H/U",
			"emergencyContact": {},
			"capacityProviderQuoteNumber": "{$scac}_{$scenario_number}_$(date +%s)",
			"apiConfiguration": {
				"noteConfiguration": {
					"enableTruncation": true
				},
				"allowUnsupportedAccessorials": true,
				"pickupOnly": false
			}
		}
		EOF
		)
		curl_call=$(cat <<-EOF
			$curl_template '$request_data'
		EOF
		)
		
		if [ "$flg_generate_output" == "true" ]; then	
			echo "$curl_call" > "$(pwd)/$output_folder/${curl_call_scenario_file_prefix}_$scenario_number.txt"
		fi
		response=$(eval "$curl_call" | jq)
		dash_count=$(($total_status_output_length - ${#scenario_name} - ${#scenario_desc} - 1))
		dashes=$(printf '%*s' "$dash_count" | tr ' ' '-')
		if [ "$flg_use_quiet_mode" == "false" ]; then
			echo -e "$scenario_name $scenario_desc response:\n$(echo "$response" | jq)"
		else
			echo "$scenario_name $scenario_desc $dashes Status code: $(print_status_code "$response")"
		fi
	fi

	scenario_number="03"
	scenario_name="Scenario $scenario_number"
	scenario_desc="(dimensions: 10x10x10)"
	if [[ ("$flg_all" == "true" || " ${scenarios_to_run[@]} " =~ " $scenario_number ") && ! " ${scenarios_to_exclude[@]} " =~ " $scenario_number " ]]; then
	
		request_data=$(cat <<-EOF
		{
			"weightUnit": "LB",
			"lengthUnit": "IN",
			"paymentTermsOverride": "PREPAID",
			"directionOverride": "SHIPPER",
			"capacityProviderAccountGroup": {
				"code": "$account_group",
				"accounts": [
					{
						"code": "$scac"
					}
				]
			},
			"originLocation": {
				"address": {
					"country": "CA",
					"postalCode": "N0B1X0",
					"addressLines": [
						"1270 Geddes St"
					],
					"city": "Hawkesville $scenario_name",
					"state": "ON"
				},
				"contact": {
					"companyName": "A M I ATTACHMENTS INC",
					"contactName": "Darlene Ward",
					"phoneNumber": "5196993923",
					"email": "darlene.w@amiattachments.com"
				}
			},
			"destinationLocation": {
				"address": {
					"country": "CA",
					"postalCode": "T5M 2S1",
					"addressLines": [
						"16116  -111 Avenue Northwest"
					],
					"city": "Edmonton $scenario_name",
					"state": "AB"
				},
				"contact": {
					"companyName": "SMS Equipment Inc.",
					"contactName": "AARON RYAN",
					"phoneNumber": "7804512630"
				}
			},
			"requesterLocation": {
				"address": {
					"country": "CA",
					"postalCode": "N0B1X0",
					"addressLines": [
						"1270 Geddes St"
					],
					"city": "Hawkesville $scenario_name",
					"state": "ON"
				},
				"contact": {
					"companyName": "A M I ATTACHMENTS INC",
					"contactName": "Darlene Ward",
					"phoneNumber": "5196993923",
					"email": "darlene.w@amiattachments.com"
				}
			},
			"lineItems": [
				{
					"freightClass": "70",
					"packageType": "PLT",
					"totalWeight": 180.0,
					"packageDimensions": {
						"length": 10.0,
						"width": 10.0,
						"height": 10.0
					},
					"totalPackages": 1,
					"totalPieces": 1,
					"description": "$scenario_name",
					"stackable": false
				}
			],
			"pickupWindow": {
				"date": "$(date -d 'tomorrow' +'%Y-%m-%d')",
				"startTime": "$(date -d 'tomorrow' +'%H:%M')",
				"endTime": "$(date -d 'tomorrow 6 hours' +'%H:%M')"
			},
			"deliveryWindow": {
				"date": "$(date -d '2 days' +'%Y-%m-%d')",
				"startTime": "$(date -d '2 days' +'%H:%M')",
				"endTime": "$(date -d '2 days 6 hours' +'%H:%M')"
			},
			"carrierCode": "$scac",
			"shipmentIdentifiers": [
				{
					"type": "CUSTOMER_REFERENCE",
					"value": "{$scac}_dispatch_test_{$scenario_number}_$(date +%s)"
				},
				{
					"type": "PURCHASE_ORDER",
					"value": "{$scac}_dispatch_test_{$scenario_number}_$(date +%s)"
				}
			],
			"accessorialServices": [],
			"pickupNote": "TOTAL 1 H/U",
			"emergencyContact": {},
			"capacityProviderQuoteNumber": "{$scac}_{$scenario_number}_$(date +%s)",
			"apiConfiguration": {
				"noteConfiguration": {
					"enableTruncation": true
				},
				"allowUnsupportedAccessorials": true,
				"pickupOnly": false
			}
		}
		EOF
		)
		curl_call=$(cat <<-EOF
			$curl_template '$request_data'
		EOF
		)
		
		if [ "$flg_generate_output" == "true" ]; then	
			echo "$curl_call" > "$(pwd)/$output_folder/${curl_call_scenario_file_prefix}_$scenario_number.txt"
		fi
		response=$(eval "$curl_call" | jq)
		dash_count=$(($total_status_output_length - ${#scenario_name} - ${#scenario_desc} - 1))
		dashes=$(printf '%*s' "$dash_count" | tr ' ' '-')
		if [ "$flg_use_quiet_mode" == "false" ]; then
			echo -e "$scenario_name $scenario_desc response:\n$(echo "$response" | jq)"
		else
			echo "$scenario_name $scenario_desc $dashes Status code: $(print_status_code "$response")"
		fi
	fi

	scenario_number="04"
	scenario_name="Scenario $scenario_number"
	scenario_desc="(dimensions: 0x0x0)"
	if [[ ("$flg_all" == "true" || " ${scenarios_to_run[@]} " =~ " $scenario_number ") && ! " ${scenarios_to_exclude[@]} " =~ " $scenario_number " ]]; then
	
		request_data=$(cat <<-EOF
		{
			"weightUnit": "LB",
			"lengthUnit": "IN",
			"paymentTermsOverride": "PREPAID",
			"directionOverride": "SHIPPER",
			"capacityProviderAccountGroup": {
				"code": "$account_group",
				"accounts": [
					{
						"code": "$scac"
					}
				]
			},
			"originLocation": {
				"address": {
					"country": "CA",
					"postalCode": "N0B1X0",
					"addressLines": [
						"1270 Geddes St"
					],
					"city": "Hawkesville $scenario_name",
					"state": "ON"
				},
				"contact": {
					"companyName": "A M I ATTACHMENTS INC",
					"contactName": "Darlene Ward",
					"phoneNumber": "5196993923",
					"email": "darlene.w@amiattachments.com"
				}
			},
			"destinationLocation": {
				"address": {
					"country": "CA",
					"postalCode": "T5M 2S1",
					"addressLines": [
						"16116  -111 Avenue Northwest"
					],
					"city": "Edmonton $scenario_name",
					"state": "AB"
				},
				"contact": {
					"companyName": "SMS Equipment Inc.",
					"contactName": "AARON RYAN",
					"phoneNumber": "7804512630"
				}
			},
			"requesterLocation": {
				"address": {
					"country": "CA",
					"postalCode": "N0B1X0",
					"addressLines": [
						"1270 Geddes St"
					],
					"city": "Hawkesville $scenario_name",
					"state": "ON"
				},
				"contact": {
					"companyName": "A M I ATTACHMENTS INC",
					"contactName": "Darlene Ward",
					"phoneNumber": "5196993923",
					"email": "darlene.w@amiattachments.com"
				}
			},
			"lineItems": [
				{
					"freightClass": "70",
					"packageType": "PLT",
					"totalWeight": 180.0,
					"packageDimensions": {
						"length": 0,
						"width": 0,
						"height": 0
					},
					"totalPackages": 1,
					"totalPieces": 1,
					"description": "$scenario_name",
					"stackable": false
				}
			],
			"pickupWindow": {
				"date": "$(date -d 'tomorrow' +'%Y-%m-%d')",
				"startTime": "$(date -d 'tomorrow' +'%H:%M')",
				"endTime": "$(date -d 'tomorrow 6 hours' +'%H:%M')"
			},
			"deliveryWindow": {
				"date": "$(date -d '2 days' +'%Y-%m-%d')",
				"startTime": "$(date -d '2 days' +'%H:%M')",
				"endTime": "$(date -d '2 days 6 hours' +'%H:%M')"
			},
			"carrierCode": "$scac",
			"shipmentIdentifiers": [
				{
					"type": "CUSTOMER_REFERENCE",
					"value": "{$scac}_dispatch_test_{$scenario_number}_$(date +%s)"
				},
				{
					"type": "PURCHASE_ORDER",
					"value": "{$scac}_dispatch_test_{$scenario_number}_$(date +%s)"
				}
			],
			"accessorialServices": [],
			"pickupNote": "TOTAL 1 H/U",
			"emergencyContact": {},
			"capacityProviderQuoteNumber": "{$scac}_{$scenario_number}_$(date +%s)",
			"apiConfiguration": {
				"noteConfiguration": {
					"enableTruncation": true
				},
				"allowUnsupportedAccessorials": true,
				"pickupOnly": false
			}
		}
		EOF
		)
		curl_call=$(cat <<-EOF
			$curl_template '$request_data'
		EOF
		)
		
		if [ "$flg_generate_output" == "true" ]; then	
			echo "$curl_call" > "$(pwd)/$output_folder/${curl_call_scenario_file_prefix}_$scenario_number.txt"
		fi
		response=$(eval "$curl_call" | jq)
		dash_count=$(($total_status_output_length - ${#scenario_name} - ${#scenario_desc} - 1))
		dashes=$(printf '%*s' "$dash_count" | tr ' ' '-')
		if [ "$flg_use_quiet_mode" == "false" ]; then
			echo -e "$scenario_name $scenario_desc response:\n$(echo "$response" | jq)"
		else
			echo "$scenario_name $scenario_desc $dashes Status code: $(print_status_code "$response")"
		fi
	fi

	scenario_number="05"
	scenario_name="Scenario $scenario_number"
	scenario_desc="(dimensions: 500x500x500)"
	if [[ ("$flg_all" == "true" || " ${scenarios_to_run[@]} " =~ " $scenario_number ") && ! " ${scenarios_to_exclude[@]} " =~ " $scenario_number " ]]; then
	
		request_data=$(cat <<-EOF
		{
			"weightUnit": "LB",
			"lengthUnit": "IN",
			"paymentTermsOverride": "PREPAID",
			"directionOverride": "SHIPPER",
			"capacityProviderAccountGroup": {
				"code": "$account_group",
				"accounts": [
					{
						"code": "$scac"
					}
				]
			},
			"originLocation": {
				"address": {
					"country": "CA",
					"postalCode": "N0B1X0",
					"addressLines": [
						"1270 Geddes St"
					],
					"city": "Hawkesville $scenario_name",
					"state": "ON"
				},
				"contact": {
					"companyName": "A M I ATTACHMENTS INC",
					"contactName": "Darlene Ward",
					"phoneNumber": "5196993923",
					"email": "darlene.w@amiattachments.com"
				}
			},
			"destinationLocation": {
				"address": {
					"country": "CA",
					"postalCode": "T5M 2S1",
					"addressLines": [
						"16116  -111 Avenue Northwest"
					],
					"city": "Edmonton $scenario_name",
					"state": "AB"
				},
				"contact": {
					"companyName": "SMS Equipment Inc.",
					"contactName": "AARON RYAN",
					"phoneNumber": "7804512630"
				}
			},
			"requesterLocation": {
				"address": {
					"country": "CA",
					"postalCode": "N0B1X0",
					"addressLines": [
						"1270 Geddes St"
					],
					"city": "Hawkesville $scenario_name",
					"state": "ON"
				},
				"contact": {
					"companyName": "A M I ATTACHMENTS INC",
					"contactName": "Darlene Ward",
					"phoneNumber": "5196993923",
					"email": "darlene.w@amiattachments.com"
				}
			},
			"lineItems": [
				{
					"freightClass": "70",
					"packageType": "PLT",
					"totalWeight": 180.0,
					"packageDimensions": {
						"length": 500.0,
						"width": 500.0,
						"height": 500.0
					},
					"totalPackages": 1,
					"totalPieces": 1,
					"description": "$scenario_name",
					"stackable": false
				}
			],
			"pickupWindow": {
				"date": "$(date -d 'tomorrow' +'%Y-%m-%d')",
				"startTime": "$(date -d 'tomorrow' +'%H:%M')",
				"endTime": "$(date -d 'tomorrow 6 hours' +'%H:%M')"
			},
			"deliveryWindow": {
				"date": "$(date -d '2 days' +'%Y-%m-%d')",
				"startTime": "$(date -d '2 days' +'%H:%M')",
				"endTime": "$(date -d '2 days 6 hours' +'%H:%M')"
			},
			"carrierCode": "$scac",
			"shipmentIdentifiers": [
				{
					"type": "CUSTOMER_REFERENCE",
					"value": "{$scac}_dispatch_test_{$scenario_number}_$(date +%s)"
				},
				{
					"type": "PURCHASE_ORDER",
					"value": "{$scac}_dispatch_test_{$scenario_number}_$(date +%s)"
				}
			],
			"accessorialServices": [],
			"pickupNote": "TOTAL 1 H/U",
			"emergencyContact": {},
			"capacityProviderQuoteNumber": "{$scac}_{$scenario_number}_$(date +%s)",
			"apiConfiguration": {
				"noteConfiguration": {
					"enableTruncation": true
				},
				"allowUnsupportedAccessorials": true,
				"pickupOnly": false
			}
		}
		EOF
		)
		curl_call=$(cat <<-EOF
			$curl_template '$request_data'
		EOF
		)
		
		if [ "$flg_generate_output" == "true" ]; then	
			echo "$curl_call" > "$(pwd)/$output_folder/${curl_call_scenario_file_prefix}_$scenario_number.txt"
		fi
		response=$(eval "$curl_call" | jq)
		dash_count=$(($total_status_output_length - ${#scenario_name} - ${#scenario_desc} - 1))
		dashes=$(printf '%*s' "$dash_count" | tr ' ' '-')
		if [ "$flg_use_quiet_mode" == "false" ]; then
			echo -e "$scenario_name $scenario_desc response:\n$(echo "$response" | jq)"
		else
			echo "$scenario_name $scenario_desc $dashes Status code: $(print_status_code "$response")"
		fi
	fi

	scenario_number="06"
	scenario_name="Scenario $scenario_number"
	scenario_desc="(dimensions: null)"
	if [[ ("$flg_all" == "true" || " ${scenarios_to_run[@]} " =~ " $scenario_number ") && ! " ${scenarios_to_exclude[@]} " =~ " $scenario_number " ]]; then
	
		request_data=$(cat <<-EOF
		{
			"weightUnit": "LB",
			"lengthUnit": "IN",
			"paymentTermsOverride": "PREPAID",
			"directionOverride": "SHIPPER",
			"capacityProviderAccountGroup": {
				"code": "$account_group",
				"accounts": [
					{
						"code": "$scac"
					}
				]
			},
			"originLocation": {
				"address": {
					"country": "CA",
					"postalCode": "N0B1X0",
					"addressLines": [
						"1270 Geddes St"
					],
					"city": "Hawkesville $scenario_name",
					"state": "ON"
				},
				"contact": {
					"companyName": "A M I ATTACHMENTS INC",
					"contactName": "Darlene Ward",
					"phoneNumber": "5196993923",
					"email": "darlene.w@amiattachments.com"
				}
			},
			"destinationLocation": {
				"address": {
					"country": "CA",
					"postalCode": "T5M 2S1",
					"addressLines": [
						"16116  -111 Avenue Northwest"
					],
					"city": "Edmonton $scenario_name",
					"state": "AB"
				},
				"contact": {
					"companyName": "SMS Equipment Inc.",
					"contactName": "AARON RYAN",
					"phoneNumber": "7804512630"
				}
			},
			"requesterLocation": {
				"address": {
					"country": "CA",
					"postalCode": "N0B1X0",
					"addressLines": [
						"1270 Geddes St"
					],
					"city": "Hawkesville $scenario_name",
					"state": "ON"
				},
				"contact": {
					"companyName": "A M I ATTACHMENTS INC",
					"contactName": "Darlene Ward",
					"phoneNumber": "5196993923",
					"email": "darlene.w@amiattachments.com"
				}
			},
			"lineItems": [
				{
					"freightClass": "70",
					"packageType": "PLT",
					"totalWeight": 180.0,
					"packageDimensions": {
						"length": null,
						"width": null,
						"height": null
					},
					"totalPackages": 1,
					"totalPieces": 1,
					"description": "$scenario_name",
					"stackable": false
				}
			],
			"pickupWindow": {
				"date": "$(date -d 'tomorrow' +'%Y-%m-%d')",
				"startTime": "$(date -d 'tomorrow' +'%H:%M')",
				"endTime": "$(date -d 'tomorrow 6 hours' +'%H:%M')"
			},
			"deliveryWindow": {
				"date": "$(date -d '2 days' +'%Y-%m-%d')",
				"startTime": "$(date -d '2 days' +'%H:%M')",
				"endTime": "$(date -d '2 days 6 hours' +'%H:%M')"
			},
			"carrierCode": "$scac",
			"shipmentIdentifiers": [
				{
					"type": "CUSTOMER_REFERENCE",
					"value": "{$scac}_dispatch_test_{$scenario_number}_$(date +%s)"
				},
				{
					"type": "PURCHASE_ORDER",
					"value": "{$scac}_dispatch_test_{$scenario_number}_$(date +%s)"
				}
			],
			"accessorialServices": [],
			"pickupNote": "TOTAL 1 H/U",
			"emergencyContact": {},
			"capacityProviderQuoteNumber": "{$scac}_{$scenario_number}_$(date +%s)",
			"apiConfiguration": {
				"noteConfiguration": {
					"enableTruncation": true
				},
				"allowUnsupportedAccessorials": true,
				"pickupOnly": false
			}
		}
		EOF
		)
		curl_call=$(cat <<-EOF
			$curl_template '$request_data'
		EOF
		)
		
		if [ "$flg_generate_output" == "true" ]; then	
			echo "$curl_call" > "$(pwd)/$output_folder/${curl_call_scenario_file_prefix}_$scenario_number.txt"
		fi
		response=$(eval "$curl_call" | jq)
		dash_count=$(($total_status_output_length - ${#scenario_name} - ${#scenario_desc} - 1))
		dashes=$(printf '%*s' "$dash_count" | tr ' ' '-')
		if [ "$flg_use_quiet_mode" == "false" ]; then
			echo -e "$scenario_name $scenario_desc response:\n$(echo "$response" | jq)"
		else
			echo "$scenario_name $scenario_desc $dashes Status code: $(print_status_code "$response")"
		fi
	fi



	scenario_number="07"
	scenario_name="Scenario $scenario_number"
	scenario_desc="(weight: 1000 lbs)"
	if [[ ("$flg_all" == "true" || " ${scenarios_to_run[@]} " =~ " $scenario_number ") && ! " ${scenarios_to_exclude[@]} " =~ " $scenario_number " ]]; then
	
		request_data=$(cat <<-EOF
		{
			"weightUnit": "LB",
			"lengthUnit": "IN",
			"paymentTermsOverride": "PREPAID",
			"directionOverride": "SHIPPER",
			"capacityProviderAccountGroup": {
				"code": "$account_group",
				"accounts": [
					{
						"code": "$scac"
					}
				]
			},
			"originLocation": {
				"address": {
					"country": "CA",
					"postalCode": "N0B1X0",
					"addressLines": [
						"1270 Geddes St"
					],
					"city": "Hawkesville $scenario_name",
					"state": "ON"
				},
				"contact": {
					"companyName": "A M I ATTACHMENTS INC",
					"contactName": "Darlene Ward",
					"phoneNumber": "5196993923",
					"email": "darlene.w@amiattachments.com"
				}
			},
			"destinationLocation": {
				"address": {
					"country": "CA",
					"postalCode": "T5M 2S1",
					"addressLines": [
						"16116  -111 Avenue Northwest"
					],
					"city": "Edmonton $scenario_name",
					"state": "AB"
				},
				"contact": {
					"companyName": "SMS Equipment Inc.",
					"contactName": "AARON RYAN",
					"phoneNumber": "7804512630"
				}
			},
			"requesterLocation": {
				"address": {
					"country": "CA",
					"postalCode": "N0B1X0",
					"addressLines": [
						"1270 Geddes St"
					],
					"city": "Hawkesville $scenario_name",
					"state": "ON"
				},
				"contact": {
					"companyName": "A M I ATTACHMENTS INC",
					"contactName": "Darlene Ward",
					"phoneNumber": "5196993923",
					"email": "darlene.w@amiattachments.com"
				}
			},
			"lineItems": [
				{
					"freightClass": "70",
					"packageType": "PLT",
					"totalWeight": 1000.0,
					"packageDimensions": {
						"length": 10.0,
						"width": 10.0,
						"height": 10.0
					},
					"totalPackages": 1,
					"totalPieces": 1,
					"description": "$scenario_name",
					"stackable": false
				}
			],
			"pickupWindow": {
				"date": "$(date -d 'tomorrow' +'%Y-%m-%d')",
				"startTime": "$(date -d 'tomorrow' +'%H:%M')",
				"endTime": "$(date -d 'tomorrow 6 hours' +'%H:%M')"
			},
			"deliveryWindow": {
				"date": "$(date -d '2 days' +'%Y-%m-%d')",
				"startTime": "$(date -d '2 days' +'%H:%M')",
				"endTime": "$(date -d '2 days 6 hours' +'%H:%M')"
			},
			"carrierCode": "$scac",
			"shipmentIdentifiers": [
				{
					"type": "CUSTOMER_REFERENCE",
					"value": "{$scac}_dispatch_test_{$scenario_number}_$(date +%s)"
				},
				{
					"type": "PURCHASE_ORDER",
					"value": "{$scac}_dispatch_test_{$scenario_number}_$(date +%s)"
				}
			],
			"accessorialServices": [],
			"pickupNote": "TOTAL 1 H/U",
			"emergencyContact": {},
			"capacityProviderQuoteNumber": "{$scac}_{$scenario_number}_$(date +%s)",
			"apiConfiguration": {
				"noteConfiguration": {
					"enableTruncation": true
				},
				"allowUnsupportedAccessorials": true,
				"pickupOnly": false
			}
		}
		EOF
		)
		curl_call=$(cat <<-EOF
			$curl_template '$request_data'
		EOF
		)
		
		if [ "$flg_generate_output" == "true" ]; then	
			echo "$curl_call" > "$(pwd)/$output_folder/${curl_call_scenario_file_prefix}_$scenario_number.txt"
		fi
		response=$(eval "$curl_call" | jq)
		dash_count=$(($total_status_output_length - ${#scenario_name} - ${#scenario_desc} - 1))
		dashes=$(printf '%*s' "$dash_count" | tr ' ' '-')
		if [ "$flg_use_quiet_mode" == "false" ]; then
			echo -e "$scenario_name $scenario_desc response:\n$(echo "$response" | jq)"
		else
			echo "$scenario_name $scenario_desc $dashes Status code: $(print_status_code "$response")"
		fi
	fi


	scenario_number="08"
	scenario_name="Scenario $scenario_number"
	scenario_desc="(weight: 0 lbs)"
	if [[ ("$flg_all" == "true" || " ${scenarios_to_run[@]} " =~ " $scenario_number ") && ! " ${scenarios_to_exclude[@]} " =~ " $scenario_number " ]]; then
	
		request_data=$(cat <<-EOF
		{
			"weightUnit": "LB",
			"lengthUnit": "IN",
			"paymentTermsOverride": "PREPAID",
			"directionOverride": "SHIPPER",
			"capacityProviderAccountGroup": {
				"code": "$account_group",
				"accounts": [
					{
						"code": "$scac"
					}
				]
			},
			"originLocation": {
				"address": {
					"country": "CA",
					"postalCode": "N0B1X0",
					"addressLines": [
						"1270 Geddes St"
					],
					"city": "Hawkesville $scenario_name",
					"state": "ON"
				},
				"contact": {
					"companyName": "A M I ATTACHMENTS INC",
					"contactName": "Darlene Ward",
					"phoneNumber": "5196993923",
					"email": "darlene.w@amiattachments.com"
				}
			},
			"destinationLocation": {
				"address": {
					"country": "CA",
					"postalCode": "T5M 2S1",
					"addressLines": [
						"16116  -111 Avenue Northwest"
					],
					"city": "Edmonton $scenario_name",
					"state": "AB"
				},
				"contact": {
					"companyName": "SMS Equipment Inc.",
					"contactName": "AARON RYAN",
					"phoneNumber": "7804512630"
				}
			},
			"requesterLocation": {
				"address": {
					"country": "CA",
					"postalCode": "N0B1X0",
					"addressLines": [
						"1270 Geddes St"
					],
					"city": "Hawkesville $scenario_name",
					"state": "ON"
				},
				"contact": {
					"companyName": "A M I ATTACHMENTS INC",
					"contactName": "Darlene Ward",
					"phoneNumber": "5196993923",
					"email": "darlene.w@amiattachments.com"
				}
			},
			"lineItems": [
				{
					"freightClass": "70",
					"packageType": "PLT",
					"totalWeight": 0,
					"packageDimensions": {
						"length": 10.0,
						"width": 10.0,
						"height": 10.0
					},
					"totalPackages": 1,
					"totalPieces": 1,
					"description": "$scenario_name",
					"stackable": false
				}
			],
			"pickupWindow": {
				"date": "$(date -d 'tomorrow' +'%Y-%m-%d')",
				"startTime": "$(date -d 'tomorrow' +'%H:%M')",
				"endTime": "$(date -d 'tomorrow 6 hours' +'%H:%M')"
			},
			"deliveryWindow": {
				"date": "$(date -d '2 days' +'%Y-%m-%d')",
				"startTime": "$(date -d '2 days' +'%H:%M')",
				"endTime": "$(date -d '2 days 6 hours' +'%H:%M')"
			},
			"carrierCode": "$scac",
			"shipmentIdentifiers": [
				{
					"type": "CUSTOMER_REFERENCE",
					"value": "{$scac}_dispatch_test_{$scenario_number}_$(date +%s)"
				},
				{
					"type": "PURCHASE_ORDER",
					"value": "{$scac}_dispatch_test_{$scenario_number}_$(date +%s)"
				}
			],
			"accessorialServices": [],
			"pickupNote": "TOTAL 1 H/U",
			"emergencyContact": {},
			"capacityProviderQuoteNumber": "{$scac}_{$scenario_number}_$(date +%s)",
			"apiConfiguration": {
				"noteConfiguration": {
					"enableTruncation": true
				},
				"allowUnsupportedAccessorials": true,
				"pickupOnly": false
			}
		}
		EOF
		)
		curl_call=$(cat <<-EOF
			$curl_template '$request_data'
		EOF
		)
		
		if [ "$flg_generate_output" == "true" ]; then	
			echo "$curl_call" > "$(pwd)/$output_folder/${curl_call_scenario_file_prefix}_$scenario_number.txt"
		fi
		response=$(eval "$curl_call" | jq)
		dash_count=$(($total_status_output_length - ${#scenario_name} - ${#scenario_desc} - 1))
		dashes=$(printf '%*s' "$dash_count" | tr ' ' '-')
		if [ "$flg_use_quiet_mode" == "false" ]; then
			echo -e "$scenario_name $scenario_desc response:\n$(echo "$response" | jq)"
		else
			echo "$scenario_name $scenario_desc $dashes Status code: $(print_status_code "$response")"
		fi
	fi

	scenario_number="09"
	scenario_name="Scenario $scenario_number"
	scenario_desc="(weight: 5000 lbs)"
	if [[ ("$flg_all" == "true" || " ${scenarios_to_run[@]} " =~ " $scenario_number ") && ! " ${scenarios_to_exclude[@]} " =~ " $scenario_number " ]]; then
	
		request_data=$(cat <<-EOF
		{
			"weightUnit": "LB",
			"lengthUnit": "IN",
			"paymentTermsOverride": "PREPAID",
			"directionOverride": "SHIPPER",
			"capacityProviderAccountGroup": {
				"code": "$account_group",
				"accounts": [
					{
						"code": "$scac"
					}
				]
			},
			"originLocation": {
				"address": {
					"country": "CA",
					"postalCode": "N0B1X0",
					"addressLines": [
						"1270 Geddes St"
					],
					"city": "Hawkesville $scenario_name",
					"state": "ON"
				},
				"contact": {
					"companyName": "A M I ATTACHMENTS INC",
					"contactName": "Darlene Ward",
					"phoneNumber": "5196993923",
					"email": "darlene.w@amiattachments.com"
				}
			},
			"destinationLocation": {
				"address": {
					"country": "CA",
					"postalCode": "T5M 2S1",
					"addressLines": [
						"16116  -111 Avenue Northwest"
					],
					"city": "Edmonton $scenario_name",
					"state": "AB"
				},
				"contact": {
					"companyName": "SMS Equipment Inc.",
					"contactName": "AARON RYAN",
					"phoneNumber": "7804512630"
				}
			},
			"requesterLocation": {
				"address": {
					"country": "CA",
					"postalCode": "N0B1X0",
					"addressLines": [
						"1270 Geddes St"
					],
					"city": "Hawkesville $scenario_name",
					"state": "ON"
				},
				"contact": {
					"companyName": "A M I ATTACHMENTS INC",
					"contactName": "Darlene Ward",
					"phoneNumber": "5196993923",
					"email": "darlene.w@amiattachments.com"
				}
			},
			"lineItems": [
				{
					"freightClass": "70",
					"packageType": "PLT",
					"totalWeight": 5000,
					"packageDimensions": {
						"length": 10.0,
						"width": 10.0,
						"height": 10.0
					},
					"totalPackages": 1,
					"totalPieces": 1,
					"description": "$scenario_name",
					"stackable": false
				}
			],
			"pickupWindow": {
				"date": "$(date -d 'tomorrow' +'%Y-%m-%d')",
				"startTime": "$(date -d 'tomorrow' +'%H:%M')",
				"endTime": "$(date -d 'tomorrow 6 hours' +'%H:%M')"
			},
			"deliveryWindow": {
				"date": "$(date -d '2 days' +'%Y-%m-%d')",
				"startTime": "$(date -d '2 days' +'%H:%M')",
				"endTime": "$(date -d '2 days 6 hours' +'%H:%M')"
			},
			"carrierCode": "$scac",
			"shipmentIdentifiers": [
				{
					"type": "CUSTOMER_REFERENCE",
					"value": "{$scac}_dispatch_test_{$scenario_number}_$(date +%s)"
				},
				{
					"type": "PURCHASE_ORDER",
					"value": "{$scac}_dispatch_test_{$scenario_number}_$(date +%s)"
				}
			],
			"accessorialServices": [],
			"pickupNote": "TOTAL 1 H/U",
			"emergencyContact": {},
			"capacityProviderQuoteNumber": "{$scac}_{$scenario_number}_$(date +%s)",
			"apiConfiguration": {
				"noteConfiguration": {
					"enableTruncation": true
				},
				"allowUnsupportedAccessorials": true,
				"pickupOnly": false
			}
		}
		EOF
		)
		curl_call=$(cat <<-EOF
			$curl_template '$request_data'
		EOF
		)
		
		if [ "$flg_generate_output" == "true" ]; then	
			echo "$curl_call" > "$(pwd)/$output_folder/${curl_call_scenario_file_prefix}_$scenario_number.txt"
		fi
		response=$(eval "$curl_call" | jq)
		dash_count=$(($total_status_output_length - ${#scenario_name} - ${#scenario_desc} - 1))
		dashes=$(printf '%*s' "$dash_count" | tr ' ' '-')
		if [ "$flg_use_quiet_mode" == "false" ]; then
			echo -e "$scenario_name $scenario_desc response:\n$(echo "$response" | jq)"
		else
			echo "$scenario_name $scenario_desc $dashes Status code: $(print_status_code "$response")"
		fi
	fi


	scenario_number="10"
	scenario_name="Scenario $scenario_number"
	scenario_desc="(weight: null)"
	if [[ ("$flg_all" == "true" || " ${scenarios_to_run[@]} " =~ " $scenario_number ") && ! " ${scenarios_to_exclude[@]} " =~ " $scenario_number " ]]; then
	
		request_data=$(cat <<-EOF
		{
			"weightUnit": "LB",
			"lengthUnit": "IN",
			"paymentTermsOverride": "PREPAID",
			"directionOverride": "SHIPPER",
			"capacityProviderAccountGroup": {
				"code": "$account_group",
				"accounts": [
					{
						"code": "$scac"
					}
				]
			},
			"originLocation": {
				"address": {
					"country": "CA",
					"postalCode": "N0B1X0",
					"addressLines": [
						"1270 Geddes St"
					],
					"city": "Hawkesville $scenario_name",
					"state": "ON"
				},
				"contact": {
					"companyName": "A M I ATTACHMENTS INC",
					"contactName": "Darlene Ward",
					"phoneNumber": "5196993923",
					"email": "darlene.w@amiattachments.com"
				}
			},
			"destinationLocation": {
				"address": {
					"country": "CA",
					"postalCode": "T5M 2S1",
					"addressLines": [
						"16116  -111 Avenue Northwest"
					],
					"city": "Edmonton $scenario_name",
					"state": "AB"
				},
				"contact": {
					"companyName": "SMS Equipment Inc.",
					"contactName": "AARON RYAN",
					"phoneNumber": "7804512630"
				}
			},
			"requesterLocation": {
				"address": {
					"country": "CA",
					"postalCode": "N0B1X0",
					"addressLines": [
						"1270 Geddes St"
					],
					"city": "Hawkesville $scenario_name",
					"state": "ON"
				},
				"contact": {
					"companyName": "A M I ATTACHMENTS INC",
					"contactName": "Darlene Ward",
					"phoneNumber": "5196993923",
					"email": "darlene.w@amiattachments.com"
				}
			},
			"lineItems": [
				{
					"freightClass": "70",
					"packageType": "PLT",
					"totalWeight": null,
					"packageDimensions": {
						"length": 10.0,
						"width": 10.0,
						"height": 10.0
					},
					"totalPackages": 1,
					"totalPieces": 1,
					"description": "$scenario_name",
					"stackable": false
				}
			],
			"pickupWindow": {
				"date": "$(date -d 'tomorrow' +'%Y-%m-%d')",
				"startTime": "$(date -d 'tomorrow' +'%H:%M')",
				"endTime": "$(date -d 'tomorrow 6 hours' +'%H:%M')"
			},
			"deliveryWindow": {
				"date": "$(date -d '2 days' +'%Y-%m-%d')",
				"startTime": "$(date -d '2 days' +'%H:%M')",
				"endTime": "$(date -d '2 days 6 hours' +'%H:%M')"
			},
			"carrierCode": "$scac",
			"shipmentIdentifiers": [
				{
					"type": "CUSTOMER_REFERENCE",
					"value": "{$scac}_dispatch_test_{$scenario_number}_$(date +%s)"
				},
				{
					"type": "PURCHASE_ORDER",
					"value": "{$scac}_dispatch_test_{$scenario_number}_$(date +%s)"
				}
			],
			"accessorialServices": [],
			"pickupNote": "TOTAL 1 H/U",
			"emergencyContact": {},
			"capacityProviderQuoteNumber": "{$scac}_{$scenario_number}_$(date +%s)",
			"apiConfiguration": {
				"noteConfiguration": {
					"enableTruncation": true
				},
				"allowUnsupportedAccessorials": true,
				"pickupOnly": false
			}
		}
		EOF
		)
		curl_call=$(cat <<-EOF
			$curl_template '$request_data'
		EOF
		)
		
		if [ "$flg_generate_output" == "true" ]; then	
			echo "$curl_call" > "$(pwd)/$output_folder/${curl_call_scenario_file_prefix}_$scenario_number.txt"
		fi
		response=$(eval "$curl_call" | jq)
		dash_count=$(($total_status_output_length - ${#scenario_name} - ${#scenario_desc} - 1))
		dashes=$(printf '%*s' "$dash_count" | tr ' ' '-')
		if [ "$flg_use_quiet_mode" == "false" ]; then
			echo -e "$scenario_name $scenario_desc response:\n$(echo "$response" | jq)"
		else
			echo "$scenario_name $scenario_desc $dashes Status code: $(print_status_code "$response")"
		fi
	fi


	scenario_number="11-1"
	scenario_name="Scenario $scenario_number"
	scenario_desc="(2 pallets)"
	if [[ ("$flg_all" == "true" || " ${scenarios_to_run[@]} " =~ " $scenario_number ") && ! " ${scenarios_to_exclude[@]} " =~ " $scenario_number " ]]; then
	
		request_data=$(cat <<-EOF
		{
			"weightUnit": "LB",
			"lengthUnit": "IN",
			"paymentTermsOverride": "PREPAID",
			"directionOverride": "SHIPPER",
			"capacityProviderAccountGroup": {
				"code": "$account_group",
				"accounts": [
					{
						"code": "$scac"
					}
				]
			},
			"originLocation": {
				"address": {
					"country": "CA",
					"postalCode": "N0B1X0",
					"addressLines": [
						"1270 Geddes St"
					],
					"city": "Hawkesville $scenario_name",
					"state": "ON"
				},
				"contact": {
					"companyName": "A M I ATTACHMENTS INC",
					"contactName": "Darlene Ward",
					"phoneNumber": "5196993923",
					"email": "darlene.w@amiattachments.com"
				}
			},
			"destinationLocation": {
				"address": {
					"country": "CA",
					"postalCode": "T5M 2S1",
					"addressLines": [
						"16116  -111 Avenue Northwest"
					],
					"city": "Edmonton $scenario_name",
					"state": "AB"
				},
				"contact": {
					"companyName": "SMS Equipment Inc.",
					"contactName": "AARON RYAN",
					"phoneNumber": "7804512630"
				}
			},
			"requesterLocation": {
				"address": {
					"country": "CA",
					"postalCode": "N0B1X0",
					"addressLines": [
						"1270 Geddes St"
					],
					"city": "Hawkesville $scenario_name",
					"state": "ON"
				},
				"contact": {
					"companyName": "A M I ATTACHMENTS INC",
					"contactName": "Darlene Ward",
					"phoneNumber": "5196993923",
					"email": "darlene.w@amiattachments.com"
				}
			},
			"lineItems": [
				{
					"freightClass": "70",
					"packageType": "PLT",
					"totalWeight": 1000.0,
					"packageDimensions": {
						"length": 10.0,
						"width": 10.0,
						"height": 10.0
					},
					"totalPackages": 2,
					"totalPieces": 1,
					"description": "$scenario_name",
					"stackable": false
				}
			],
			"pickupWindow": {
				"date": "$(date -d 'tomorrow' +'%Y-%m-%d')",
				"startTime": "$(date -d 'tomorrow' +'%H:%M')",
				"endTime": "$(date -d 'tomorrow 6 hours' +'%H:%M')"
			},
			"deliveryWindow": {
				"date": "$(date -d '2 days' +'%Y-%m-%d')",
				"startTime": "$(date -d '2 days' +'%H:%M')",
				"endTime": "$(date -d '2 days 6 hours' +'%H:%M')"
			},
			"carrierCode": "$scac",
			"shipmentIdentifiers": [
				{
					"type": "CUSTOMER_REFERENCE",
					"value": "{$scac}_dispatch_test_{$scenario_number}_$(date +%s)"
				},
				{
					"type": "PURCHASE_ORDER",
					"value": "{$scac}_dispatch_test_{$scenario_number}_$(date +%s)"
				}
			],
			"accessorialServices": [],
			"pickupNote": "TOTAL 1 H/U",
			"emergencyContact": {},
			"capacityProviderQuoteNumber": "{$scac}_{$scenario_number}_$(date +%s)",
			"apiConfiguration": {
				"noteConfiguration": {
					"enableTruncation": true
				},
				"allowUnsupportedAccessorials": true,
				"pickupOnly": false
			}
		}
		EOF
		)
		curl_call=$(cat <<-EOF
			$curl_template '$request_data'
		EOF
		)
		
		if [ "$flg_generate_output" == "true" ]; then	
			echo "$curl_call" > "$(pwd)/$output_folder/${curl_call_scenario_file_prefix}_$scenario_number.txt"
		fi
		response=$(eval "$curl_call" | jq)
		dash_count=$(($total_status_output_length - ${#scenario_name} - ${#scenario_desc} - 1))
		dashes=$(printf '%*s' "$dash_count" | tr ' ' '-')
		if [ "$flg_use_quiet_mode" == "false" ]; then
			echo -e "$scenario_name $scenario_desc response:\n$(echo "$response" | jq)"
		else
			echo "$scenario_name $scenario_desc $dashes Status code: $(print_status_code "$response")"
		fi
	fi


	scenario_number="11-2"
	scenario_name="Scenario $scenario_number"
	scenario_desc="(3 cartons)"
	if [[ ("$flg_all" == "true" || " ${scenarios_to_run[@]} " =~ " $scenario_number ") && ! " ${scenarios_to_exclude[@]} " =~ " $scenario_number " ]]; then
	
		request_data=$(cat <<-EOF
		{
			"weightUnit": "LB",
			"lengthUnit": "IN",
			"paymentTermsOverride": "PREPAID",
			"directionOverride": "SHIPPER",
			"capacityProviderAccountGroup": {
				"code": "$account_group",
				"accounts": [
					{
						"code": "$scac"
					}
				]
			},
			"originLocation": {
				"address": {
					"country": "CA",
					"postalCode": "N0B1X0",
					"addressLines": [
						"1270 Geddes St"
					],
					"city": "Hawkesville $scenario_name",
					"state": "ON"
				},
				"contact": {
					"companyName": "A M I ATTACHMENTS INC",
					"contactName": "Darlene Ward",
					"phoneNumber": "5196993923",
					"email": "darlene.w@amiattachments.com"
				}
			},
			"destinationLocation": {
				"address": {
					"country": "CA",
					"postalCode": "T5M 2S1",
					"addressLines": [
						"16116  -111 Avenue Northwest"
					],
					"city": "Edmonton $scenario_name",
					"state": "AB"
				},
				"contact": {
					"companyName": "SMS Equipment Inc.",
					"contactName": "AARON RYAN",
					"phoneNumber": "7804512630"
				}
			},
			"requesterLocation": {
				"address": {
					"country": "CA",
					"postalCode": "N0B1X0",
					"addressLines": [
						"1270 Geddes St"
					],
					"city": "Hawkesville $scenario_name",
					"state": "ON"
				},
				"contact": {
					"companyName": "A M I ATTACHMENTS INC",
					"contactName": "Darlene Ward",
					"phoneNumber": "5196993923",
					"email": "darlene.w@amiattachments.com"
				}
			},
			"lineItems": [
				{
					"freightClass": "70",
					"packageType": "CARTON",
					"totalWeight": 1000.0,
					"packageDimensions": {
						"length": 10.0,
						"width": 10.0,
						"height": 10.0
					},
					"totalPackages": 3,
					"totalPieces": 1,
					"description": "$scenario_name",
					"stackable": false
				}
			],
			"pickupWindow": {
				"date": "$(date -d 'tomorrow' +'%Y-%m-%d')",
				"startTime": "$(date -d 'tomorrow' +'%H:%M')",
				"endTime": "$(date -d 'tomorrow 6 hours' +'%H:%M')"
			},
			"deliveryWindow": {
				"date": "$(date -d '2 days' +'%Y-%m-%d')",
				"startTime": "$(date -d '2 days' +'%H:%M')",
				"endTime": "$(date -d '2 days 6 hours' +'%H:%M')"
			},
			"carrierCode": "$scac",
			"shipmentIdentifiers": [
				{
					"type": "CUSTOMER_REFERENCE",
					"value": "{$scac}_dispatch_test_{$scenario_number}_$(date +%s)"
				},
				{
					"type": "PURCHASE_ORDER",
					"value": "{$scac}_dispatch_test_{$scenario_number}_$(date +%s)"
				}
			],
			"accessorialServices": [],
			"pickupNote": "TOTAL 1 H/U",
			"emergencyContact": {},
			"capacityProviderQuoteNumber": "{$scac}_{$scenario_number}_$(date +%s)",
			"apiConfiguration": {
				"noteConfiguration": {
					"enableTruncation": true
				},
				"allowUnsupportedAccessorials": true,
				"pickupOnly": false
			}
		}
		EOF
		)
		curl_call=$(cat <<-EOF
			$curl_template '$request_data'
		EOF
		)
		
		if [ "$flg_generate_output" == "true" ]; then	
			echo "$curl_call" > "$(pwd)/$output_folder/${curl_call_scenario_file_prefix}_$scenario_number.txt"
		fi
		response=$(eval "$curl_call" | jq)
		dash_count=$(($total_status_output_length - ${#scenario_name} - ${#scenario_desc} - 1))
		dashes=$(printf '%*s' "$dash_count" | tr ' ' '-')
		if [ "$flg_use_quiet_mode" == "false" ]; then
			echo -e "$scenario_name $scenario_desc response:\n$(echo "$response" | jq)"
		else
			echo "$scenario_name $scenario_desc $dashes Status code: $(print_status_code "$response")"
		fi
	fi

	scenario_number="12-1"
	scenario_name="Scenario $scenario_number"
	scenario_desc="(package type: BAG)"
	if [[ ("$flg_all" == "true" || " ${scenarios_to_run[@]} " =~ " $scenario_number ") && ! " ${scenarios_to_exclude[@]} " =~ " $scenario_number " ]]; then
	
		request_data=$(cat <<-EOF
		{
			"weightUnit": "LB",
			"lengthUnit": "IN",
			"paymentTermsOverride": "PREPAID",
			"directionOverride": "SHIPPER",
			"capacityProviderAccountGroup": {
				"code": "$account_group",
				"accounts": [
					{
						"code": "$scac"
					}
				]
			},
			"originLocation": {
				"address": {
					"country": "CA",
					"postalCode": "N0B1X0",
					"addressLines": [
						"1270 Geddes St"
					],
					"city": "Hawkesville $scenario_name",
					"state": "ON"
				},
				"contact": {
					"companyName": "A M I ATTACHMENTS INC",
					"contactName": "Darlene Ward",
					"phoneNumber": "5196993923",
					"email": "darlene.w@amiattachments.com"
				}
			},
			"destinationLocation": {
				"address": {
					"country": "CA",
					"postalCode": "T5M 2S1",
					"addressLines": [
						"16116  -111 Avenue Northwest"
					],
					"city": "Edmonton $scenario_name",
					"state": "AB"
				},
				"contact": {
					"companyName": "SMS Equipment Inc.",
					"contactName": "AARON RYAN",
					"phoneNumber": "7804512630"
				}
			},
			"requesterLocation": {
				"address": {
					"country": "CA",
					"postalCode": "N0B1X0",
					"addressLines": [
						"1270 Geddes St"
					],
					"city": "Hawkesville $scenario_name",
					"state": "ON"
				},
				"contact": {
					"companyName": "A M I ATTACHMENTS INC",
					"contactName": "Darlene Ward",
					"phoneNumber": "5196993923",
					"email": "darlene.w@amiattachments.com"
				}
			},
			"lineItems": [
				{
					"freightClass": "70",
					"packageType": "BAG",
					"totalWeight": 1000.0,
					"packageDimensions": {
						"length": 10.0,
						"width": 10.0,
						"height": 10.0
					},
					"totalPackages": 1,
					"totalPieces": 1,
					"description": "$scenario_name",
					"stackable": false
				}
			],
			"pickupWindow": {
				"date": "$(date -d 'tomorrow' +'%Y-%m-%d')",
				"startTime": "$(date -d 'tomorrow' +'%H:%M')",
				"endTime": "$(date -d 'tomorrow 6 hours' +'%H:%M')"
			},
			"deliveryWindow": {
				"date": "$(date -d '2 days' +'%Y-%m-%d')",
				"startTime": "$(date -d '2 days' +'%H:%M')",
				"endTime": "$(date -d '2 days 6 hours' +'%H:%M')"
			},
			"carrierCode": "$scac",
			"shipmentIdentifiers": [
				{
					"type": "CUSTOMER_REFERENCE",
					"value": "{$scac}_dispatch_test_{$scenario_number}_$(date +%s)"
				},
				{
					"type": "PURCHASE_ORDER",
					"value": "{$scac}_dispatch_test_{$scenario_number}_$(date +%s)"
				}
			],
			"accessorialServices": [],
			"pickupNote": "TOTAL 1 H/U",
			"emergencyContact": {},
			"capacityProviderQuoteNumber": "{$scac}_{$scenario_number}_$(date +%s)",
			"apiConfiguration": {
				"noteConfiguration": {
					"enableTruncation": true
				},
				"allowUnsupportedAccessorials": true,
				"pickupOnly": false
			}
		}
		EOF
		)
		curl_call=$(cat <<-EOF
			$curl_template '$request_data'
		EOF
		)
		
		if [ "$flg_generate_output" == "true" ]; then	
			echo "$curl_call" > "$(pwd)/$output_folder/${curl_call_scenario_file_prefix}_$scenario_number.txt"
		fi
		response=$(eval "$curl_call" | jq)
		dash_count=$(($total_status_output_length - ${#scenario_name} - ${#scenario_desc} - 1))
		dashes=$(printf '%*s' "$dash_count" | tr ' ' '-')
		if [ "$flg_use_quiet_mode" == "false" ]; then
			echo -e "$scenario_name $scenario_desc response:\n$(echo "$response" | jq)"
		else
			echo "$scenario_name $scenario_desc $dashes Status code: $(print_status_code "$response")"
		fi
	fi



	scenario_number="12-2"
	scenario_name="Scenario $scenario_number"
	scenario_desc="(package type: BOX)"
	if [[ ("$flg_all" == "true" || " ${scenarios_to_run[@]} " =~ " $scenario_number ") && ! " ${scenarios_to_exclude[@]} " =~ " $scenario_number " ]]; then
	
		request_data=$(cat <<-EOF
		{
			"weightUnit": "LB",
			"lengthUnit": "IN",
			"paymentTermsOverride": "PREPAID",
			"directionOverride": "SHIPPER",
			"capacityProviderAccountGroup": {
				"code": "$account_group",
				"accounts": [
					{
						"code": "$scac"
					}
				]
			},
			"originLocation": {
				"address": {
					"country": "CA",
					"postalCode": "N0B1X0",
					"addressLines": [
						"1270 Geddes St"
					],
					"city": "Hawkesville $scenario_name",
					"state": "ON"
				},
				"contact": {
					"companyName": "A M I ATTACHMENTS INC",
					"contactName": "Darlene Ward",
					"phoneNumber": "5196993923",
					"email": "darlene.w@amiattachments.com"
				}
			},
			"destinationLocation": {
				"address": {
					"country": "CA",
					"postalCode": "T5M 2S1",
					"addressLines": [
						"16116  -111 Avenue Northwest"
					],
					"city": "Edmonton $scenario_name",
					"state": "AB"
				},
				"contact": {
					"companyName": "SMS Equipment Inc.",
					"contactName": "AARON RYAN",
					"phoneNumber": "7804512630"
				}
			},
			"requesterLocation": {
				"address": {
					"country": "CA",
					"postalCode": "N0B1X0",
					"addressLines": [
						"1270 Geddes St"
					],
					"city": "Hawkesville $scenario_name",
					"state": "ON"
				},
				"contact": {
					"companyName": "A M I ATTACHMENTS INC",
					"contactName": "Darlene Ward",
					"phoneNumber": "5196993923",
					"email": "darlene.w@amiattachments.com"
				}
			},
			"lineItems": [
				{
					"freightClass": "70",
					"packageType": "BOX",
					"totalWeight": 1000.0,
					"packageDimensions": {
						"length": 10.0,
						"width": 10.0,
						"height": 10.0
					},
					"totalPackages": 1,
					"totalPieces": 1,
					"description": "$scenario_name",
					"stackable": false
				}
			],
			"pickupWindow": {
				"date": "$(date -d 'tomorrow' +'%Y-%m-%d')",
				"startTime": "$(date -d 'tomorrow' +'%H:%M')",
				"endTime": "$(date -d 'tomorrow 6 hours' +'%H:%M')"
			},
			"deliveryWindow": {
				"date": "$(date -d '2 days' +'%Y-%m-%d')",
				"startTime": "$(date -d '2 days' +'%H:%M')",
				"endTime": "$(date -d '2 days 6 hours' +'%H:%M')"
			},
			"carrierCode": "$scac",
			"shipmentIdentifiers": [
				{
					"type": "CUSTOMER_REFERENCE",
					"value": "{$scac}_dispatch_test_{$scenario_number}_$(date +%s)"
				},
				{
					"type": "PURCHASE_ORDER",
					"value": "{$scac}_dispatch_test_{$scenario_number}_$(date +%s)"
				}
			],
			"accessorialServices": [],
			"pickupNote": "TOTAL 1 H/U",
			"emergencyContact": {},
			"capacityProviderQuoteNumber": "{$scac}_{$scenario_number}_$(date +%s)",
			"apiConfiguration": {
				"noteConfiguration": {
					"enableTruncation": true
				},
				"allowUnsupportedAccessorials": true,
				"pickupOnly": false
			}
		}
		EOF
		)
		curl_call=$(cat <<-EOF
			$curl_template '$request_data'
		EOF
		)
		
		if [ "$flg_generate_output" == "true" ]; then	
			echo "$curl_call" > "$(pwd)/$output_folder/${curl_call_scenario_file_prefix}_$scenario_number.txt"
		fi
		response=$(eval "$curl_call" | jq)
		dash_count=$(($total_status_output_length - ${#scenario_name} - ${#scenario_desc} - 1))
		dashes=$(printf '%*s' "$dash_count" | tr ' ' '-')
		if [ "$flg_use_quiet_mode" == "false" ]; then
			echo -e "$scenario_name $scenario_desc response:\n$(echo "$response" | jq)"
		else
			echo "$scenario_name $scenario_desc $dashes Status code: $(print_status_code "$response")"
		fi
	fi


	scenario_number="12-3"
	scenario_name="Scenario $scenario_number"
	scenario_desc="(package type: PLT)"
	if [[ ("$flg_all" == "true" || " ${scenarios_to_run[@]} " =~ " $scenario_number ") && ! " ${scenarios_to_exclude[@]} " =~ " $scenario_number " ]]; then
	
		request_data=$(cat <<-EOF
		{
			"weightUnit": "LB",
			"lengthUnit": "IN",
			"paymentTermsOverride": "PREPAID",
			"directionOverride": "SHIPPER",
			"capacityProviderAccountGroup": {
				"code": "$account_group",
				"accounts": [
					{
						"code": "$scac"
					}
				]
			},
			"originLocation": {
				"address": {
					"country": "CA",
					"postalCode": "N0B1X0",
					"addressLines": [
						"1270 Geddes St"
					],
					"city": "Hawkesville $scenario_name",
					"state": "ON"
				},
				"contact": {
					"companyName": "A M I ATTACHMENTS INC",
					"contactName": "Darlene Ward",
					"phoneNumber": "5196993923",
					"email": "darlene.w@amiattachments.com"
				}
			},
			"destinationLocation": {
				"address": {
					"country": "CA",
					"postalCode": "T5M 2S1",
					"addressLines": [
						"16116  -111 Avenue Northwest"
					],
					"city": "Edmonton $scenario_name",
					"state": "AB"
				},
				"contact": {
					"companyName": "SMS Equipment Inc.",
					"contactName": "AARON RYAN",
					"phoneNumber": "7804512630"
				}
			},
			"requesterLocation": {
				"address": {
					"country": "CA",
					"postalCode": "N0B1X0",
					"addressLines": [
						"1270 Geddes St"
					],
					"city": "Hawkesville $scenario_name",
					"state": "ON"
				},
				"contact": {
					"companyName": "A M I ATTACHMENTS INC",
					"contactName": "Darlene Ward",
					"phoneNumber": "5196993923",
					"email": "darlene.w@amiattachments.com"
				}
			},
			"lineItems": [
				{
					"freightClass": "70",
					"packageType": "PLT",
					"totalWeight": 1000.0,
					"packageDimensions": {
						"length": 10.0,
						"width": 10.0,
						"height": 10.0
					},
					"totalPackages": 1,
					"totalPieces": 1,
					"description": "$scenario_name",
					"stackable": false
				}
			],
			"pickupWindow": {
				"date": "$(date -d 'tomorrow' +'%Y-%m-%d')",
				"startTime": "$(date -d 'tomorrow' +'%H:%M')",
				"endTime": "$(date -d 'tomorrow 6 hours' +'%H:%M')"
			},
			"deliveryWindow": {
				"date": "$(date -d '2 days' +'%Y-%m-%d')",
				"startTime": "$(date -d '2 days' +'%H:%M')",
				"endTime": "$(date -d '2 days 6 hours' +'%H:%M')"
			},
			"carrierCode": "$scac",
			"shipmentIdentifiers": [
				{
					"type": "CUSTOMER_REFERENCE",
					"value": "{$scac}_dispatch_test_{$scenario_number}_$(date +%s)"
				},
				{
					"type": "PURCHASE_ORDER",
					"value": "{$scac}_dispatch_test_{$scenario_number}_$(date +%s)"
				}
			],
			"accessorialServices": [],
			"pickupNote": "TOTAL 1 H/U",
			"emergencyContact": {},
			"capacityProviderQuoteNumber": "{$scac}_{$scenario_number}_$(date +%s)",
			"apiConfiguration": {
				"noteConfiguration": {
					"enableTruncation": true
				},
				"allowUnsupportedAccessorials": true,
				"pickupOnly": false
			}
		}
		EOF
		)
		curl_call=$(cat <<-EOF
			$curl_template '$request_data'
		EOF
		)
		
		if [ "$flg_generate_output" == "true" ]; then	
			echo "$curl_call" > "$(pwd)/$output_folder/${curl_call_scenario_file_prefix}_$scenario_number.txt"
		fi
		response=$(eval "$curl_call" | jq)
		dash_count=$(($total_status_output_length - ${#scenario_name} - ${#scenario_desc} - 1))
		dashes=$(printf '%*s' "$dash_count" | tr ' ' '-')
		if [ "$flg_use_quiet_mode" == "false" ]; then
			echo -e "$scenario_name $scenario_desc response:\n$(echo "$response" | jq)"
		else
			echo "$scenario_name $scenario_desc $dashes Status code: $(print_status_code "$response")"
		fi
	fi


	scenario_number="13-1"
	scenario_name="Scenario $scenario_number"
	scenario_desc="(unit type: SKID)"
	if [[ ("$flg_all" == "true" || " ${scenarios_to_run[@]} " =~ " $scenario_number ") && ! " ${scenarios_to_exclude[@]} " =~ " $scenario_number " ]]; then
	
		request_data=$(cat <<-EOF
		{
			"weightUnit": "LB",
			"lengthUnit": "IN",
			"paymentTermsOverride": "PREPAID",
			"directionOverride": "SHIPPER",
			"capacityProviderAccountGroup": {
				"code": "$account_group",
				"accounts": [
					{
						"code": "$scac"
					}
				]
			},
			"originLocation": {
				"address": {
					"country": "CA",
					"postalCode": "N0B1X0",
					"addressLines": [
						"1270 Geddes St"
					],
					"city": "Hawkesville $scenario_name",
					"state": "ON"
				},
				"contact": {
					"companyName": "A M I ATTACHMENTS INC",
					"contactName": "Darlene Ward",
					"phoneNumber": "5196993923",
					"email": "darlene.w@amiattachments.com"
				}
			},
			"destinationLocation": {
				"address": {
					"country": "CA",
					"postalCode": "T5M 2S1",
					"addressLines": [
						"16116  -111 Avenue Northwest"
					],
					"city": "Edmonton $scenario_name",
					"state": "AB"
				},
				"contact": {
					"companyName": "SMS Equipment Inc.",
					"contactName": "AARON RYAN",
					"phoneNumber": "7804512630"
				}
			},
			"requesterLocation": {
				"address": {
					"country": "CA",
					"postalCode": "N0B1X0",
					"addressLines": [
						"1270 Geddes St"
					],
					"city": "Hawkesville $scenario_name",
					"state": "ON"
				},
				"contact": {
					"companyName": "A M I ATTACHMENTS INC",
					"contactName": "Darlene Ward",
					"phoneNumber": "5196993923",
					"email": "darlene.w@amiattachments.com"
				}
			},
			"lineItems": [
				{
					"freightClass": "70",
					"packageType": "SKID",
					"totalWeight": 1000.0,
					"packageDimensions": {
						"length": 10.0,
						"width": 10.0,
						"height": 10.0
					},
					"totalPackages": 1,
					"totalPieces": 1,
					"description": "$scenario_name",
					"stackable": false
				}
			],
			"pickupWindow": {
				"date": "$(date -d 'tomorrow' +'%Y-%m-%d')",
				"startTime": "$(date -d 'tomorrow' +'%H:%M')",
				"endTime": "$(date -d 'tomorrow 6 hours' +'%H:%M')"
			},
			"deliveryWindow": {
				"date": "$(date -d '2 days' +'%Y-%m-%d')",
				"startTime": "$(date -d '2 days' +'%H:%M')",
				"endTime": "$(date -d '2 days 6 hours' +'%H:%M')"
			},
			"carrierCode": "$scac",
			"shipmentIdentifiers": [
				{
					"type": "CUSTOMER_REFERENCE",
					"value": "{$scac}_dispatch_test_{$scenario_number}_$(date +%s)"
				},
				{
					"type": "PURCHASE_ORDER",
					"value": "{$scac}_dispatch_test_{$scenario_number}_$(date +%s)"
				}
			],
			"accessorialServices": [],
			"pickupNote": "TOTAL 1 H/U",
			"emergencyContact": {},
			"capacityProviderQuoteNumber": "{$scac}_{$scenario_number}_$(date +%s)",
			"apiConfiguration": {
				"noteConfiguration": {
					"enableTruncation": true
				},
				"allowUnsupportedAccessorials": true,
				"pickupOnly": false
			}
		}
		EOF
		)
		curl_call=$(cat <<-EOF
			$curl_template '$request_data'
		EOF
		)
		
		if [ "$flg_generate_output" == "true" ]; then	
			echo "$curl_call" > "$(pwd)/$output_folder/${curl_call_scenario_file_prefix}_$scenario_number.txt"
		fi
		response=$(eval "$curl_call" | jq)
		dash_count=$(($total_status_output_length - ${#scenario_name} - ${#scenario_desc} - 1))
		dashes=$(printf '%*s' "$dash_count" | tr ' ' '-')
		if [ "$flg_use_quiet_mode" == "false" ]; then
			echo -e "$scenario_name $scenario_desc response:\n$(echo "$response" | jq)"
		else
			echo "$scenario_name $scenario_desc $dashes Status code: $(print_status_code "$response")"
		fi
	fi


	scenario_number="13-2"
	scenario_name="Scenario $scenario_number"
	scenario_desc="(unit type: CARTON)"
	if [[ ("$flg_all" == "true" || " ${scenarios_to_run[@]} " =~ " $scenario_number ") && ! " ${scenarios_to_exclude[@]} " =~ " $scenario_number " ]]; then
	
		request_data=$(cat <<-EOF
		{
			"weightUnit": "LB",
			"lengthUnit": "IN",
			"paymentTermsOverride": "PREPAID",
			"directionOverride": "SHIPPER",
			"capacityProviderAccountGroup": {
				"code": "$account_group",
				"accounts": [
					{
						"code": "$scac"
					}
				]
			},
			"originLocation": {
				"address": {
					"country": "CA",
					"postalCode": "N0B1X0",
					"addressLines": [
						"1270 Geddes St"
					],
					"city": "Hawkesville $scenario_name",
					"state": "ON"
				},
				"contact": {
					"companyName": "A M I ATTACHMENTS INC",
					"contactName": "Darlene Ward",
					"phoneNumber": "5196993923",
					"email": "darlene.w@amiattachments.com"
				}
			},
			"destinationLocation": {
				"address": {
					"country": "CA",
					"postalCode": "T5M 2S1",
					"addressLines": [
						"16116  -111 Avenue Northwest"
					],
					"city": "Edmonton $scenario_name",
					"state": "AB"
				},
				"contact": {
					"companyName": "SMS Equipment Inc.",
					"contactName": "AARON RYAN",
					"phoneNumber": "7804512630"
				}
			},
			"requesterLocation": {
				"address": {
					"country": "CA",
					"postalCode": "N0B1X0",
					"addressLines": [
						"1270 Geddes St"
					],
					"city": "Hawkesville $scenario_name",
					"state": "ON"
				},
				"contact": {
					"companyName": "A M I ATTACHMENTS INC",
					"contactName": "Darlene Ward",
					"phoneNumber": "5196993923",
					"email": "darlene.w@amiattachments.com"
				}
			},
			"lineItems": [
				{
					"freightClass": "70",
					"packageType": "CARTON",
					"totalWeight": 1000.0,
					"packageDimensions": {
						"length": 10.0,
						"width": 10.0,
						"height": 10.0
					},
					"totalPackages": 1,
					"totalPieces": 1,
					"description": "$scenario_name",
					"stackable": false
				}
			],
			"pickupWindow": {
				"date": "$(date -d 'tomorrow' +'%Y-%m-%d')",
				"startTime": "$(date -d 'tomorrow' +'%H:%M')",
				"endTime": "$(date -d 'tomorrow 6 hours' +'%H:%M')"
			},
			"deliveryWindow": {
				"date": "$(date -d '2 days' +'%Y-%m-%d')",
				"startTime": "$(date -d '2 days' +'%H:%M')",
				"endTime": "$(date -d '2 days 6 hours' +'%H:%M')"
			},
			"carrierCode": "$scac",
			"shipmentIdentifiers": [
				{
					"type": "CUSTOMER_REFERENCE",
					"value": "{$scac}_dispatch_test_{$scenario_number}_$(date +%s)"
				},
				{
					"type": "PURCHASE_ORDER",
					"value": "{$scac}_dispatch_test_{$scenario_number}_$(date +%s)"
				}
			],
			"accessorialServices": [],
			"pickupNote": "TOTAL 1 H/U",
			"emergencyContact": {},
			"capacityProviderQuoteNumber": "{$scac}_{$scenario_number}_$(date +%s)",
			"apiConfiguration": {
				"noteConfiguration": {
					"enableTruncation": true
				},
				"allowUnsupportedAccessorials": true,
				"pickupOnly": false
			}
		}
		EOF
		)
		curl_call=$(cat <<-EOF
			$curl_template '$request_data'
		EOF
		)
		
		if [ "$flg_generate_output" == "true" ]; then	
			echo "$curl_call" > "$(pwd)/$output_folder/${curl_call_scenario_file_prefix}_$scenario_number.txt"
		fi
		response=$(eval "$curl_call" | jq)
		dash_count=$(($total_status_output_length - ${#scenario_name} - ${#scenario_desc} - 1))
		dashes=$(printf '%*s' "$dash_count" | tr ' ' '-')
		if [ "$flg_use_quiet_mode" == "false" ]; then
			echo -e "$scenario_name $scenario_desc response:\n$(echo "$response" | jq)"
		else
			echo "$scenario_name $scenario_desc $dashes Status code: $(print_status_code "$response")"
		fi
	fi


	scenario_number="14-1"
	scenario_name="Scenario $scenario_number"
	scenario_desc="(accessorial code: HAZM)"
	if [[ ("$flg_all" == "true" || " ${scenarios_to_run[@]} " =~ " $scenario_number ") && ! " ${scenarios_to_exclude[@]} " =~ " $scenario_number " ]]; then
	
		request_data=$(cat <<-EOF
		{
			"weightUnit": "LB",
			"lengthUnit": "IN",
			"paymentTermsOverride": "PREPAID",
			"directionOverride": "SHIPPER",
			"capacityProviderAccountGroup": {
				"code": "$account_group",
				"accounts": [
					{
						"code": "$scac"
					}
				]
			},
			"originLocation": {
				"address": {
					"country": "CA",
					"postalCode": "N0B1X0",
					"addressLines": [
						"1270 Geddes St"
					],
					"city": "Hawkesville $scenario_name",
					"state": "ON"
				},
				"contact": {
					"companyName": "A M I ATTACHMENTS INC",
					"contactName": "Darlene Ward",
					"phoneNumber": "5196993923",
					"email": "darlene.w@amiattachments.com"
				}
			},
			"destinationLocation": {
				"address": {
					"country": "CA",
					"postalCode": "T5M 2S1",
					"addressLines": [
						"16116  -111 Avenue Northwest"
					],
					"city": "Edmonton $scenario_name",
					"state": "AB"
				},
				"contact": {
					"companyName": "SMS Equipment Inc.",
					"contactName": "AARON RYAN",
					"phoneNumber": "7804512630"
				}
			},
			"requesterLocation": {
				"address": {
					"country": "CA",
					"postalCode": "N0B1X0",
					"addressLines": [
						"1270 Geddes St"
					],
					"city": "Hawkesville $scenario_name",
					"state": "ON"
				},
				"contact": {
					"companyName": "A M I ATTACHMENTS INC",
					"contactName": "Darlene Ward",
					"phoneNumber": "5196993923",
					"email": "darlene.w@amiattachments.com"
				}
			},
			"lineItems": [
				{
					"freightClass": "70",
					"packageType": "CARTON",
					"totalWeight": 1000.0,
					"packageDimensions": {
						"length": 10.0,
						"width": 10.0,
						"height": 10.0
					},
					"totalPackages": 1,
					"totalPieces": 1,
					"description": "$scenario_name",
					"stackable": false
				}
			],
			"pickupWindow": {
				"date": "$(date -d 'tomorrow' +'%Y-%m-%d')",
				"startTime": "$(date -d 'tomorrow' +'%H:%M')",
				"endTime": "$(date -d 'tomorrow 6 hours' +'%H:%M')"
			},
			"deliveryWindow": {
				"date": "$(date -d '2 days' +'%Y-%m-%d')",
				"startTime": "$(date -d '2 days' +'%H:%M')",
				"endTime": "$(date -d '2 days 6 hours' +'%H:%M')"
			},
			"carrierCode": "$scac",
			"shipmentIdentifiers": [
				{
					"type": "CUSTOMER_REFERENCE",
					"value": "{$scac}_dispatch_test_{$scenario_number}_$(date +%s)"
				},
				{
					"type": "PURCHASE_ORDER",
					"value": "{$scac}_dispatch_test_{$scenario_number}_$(date +%s)"
				}
			],
			"accessorialServices": [
				{
					"code": "HAZM"
				}
			],
			"pickupNote": "TOTAL 1 H/U",
			"emergencyContact": {},
			"capacityProviderQuoteNumber": "{$scac}_{$scenario_number}_$(date +%s)",
			"apiConfiguration": {
				"noteConfiguration": {
					"enableTruncation": true
				},
				"allowUnsupportedAccessorials": true,
				"pickupOnly": false
			}
		}
		EOF
		)
		curl_call=$(cat <<-EOF
			$curl_template '$request_data'
		EOF
		)
		
		if [ "$flg_generate_output" == "true" ]; then	
			echo "$curl_call" > "$(pwd)/$output_folder/${curl_call_scenario_file_prefix}_$scenario_number.txt"
		fi
		response=$(eval "$curl_call" | jq)
		dash_count=$(($total_status_output_length - ${#scenario_name} - ${#scenario_desc} - 1))
		dashes=$(printf '%*s' "$dash_count" | tr ' ' '-')
		if [ "$flg_use_quiet_mode" == "false" ]; then
			echo -e "$scenario_name $scenario_desc response:\n$(echo "$response" | jq)"
		else
			echo "$scenario_name $scenario_desc $dashes Status code: $(print_status_code "$response")"
		fi
	fi

	scenario_number="14-2"
	scenario_name="Scenario $scenario_number"
	scenario_desc="(accessorial code: POISON)"
	if [[ ("$flg_all" == "true" || " ${scenarios_to_run[@]} " =~ " $scenario_number ") && ! " ${scenarios_to_exclude[@]} " =~ " $scenario_number " ]]; then
	
		request_data=$(cat <<-EOF
		{
			"weightUnit": "LB",
			"lengthUnit": "IN",
			"paymentTermsOverride": "PREPAID",
			"directionOverride": "SHIPPER",
			"capacityProviderAccountGroup": {
				"code": "$account_group",
				"accounts": [
					{
						"code": "$scac"
					}
				]
			},
			"originLocation": {
				"address": {
					"country": "CA",
					"postalCode": "N0B1X0",
					"addressLines": [
						"1270 Geddes St"
					],
					"city": "Hawkesville $scenario_name",
					"state": "ON"
				},
				"contact": {
					"companyName": "A M I ATTACHMENTS INC",
					"contactName": "Darlene Ward",
					"phoneNumber": "5196993923",
					"email": "darlene.w@amiattachments.com"
				}
			},
			"destinationLocation": {
				"address": {
					"country": "CA",
					"postalCode": "T5M 2S1",
					"addressLines": [
						"16116  -111 Avenue Northwest"
					],
					"city": "Edmonton $scenario_name",
					"state": "AB"
				},
				"contact": {
					"companyName": "SMS Equipment Inc.",
					"contactName": "AARON RYAN",
					"phoneNumber": "7804512630"
				}
			},
			"requesterLocation": {
				"address": {
					"country": "CA",
					"postalCode": "N0B1X0",
					"addressLines": [
						"1270 Geddes St"
					],
					"city": "Hawkesville $scenario_name",
					"state": "ON"
				},
				"contact": {
					"companyName": "A M I ATTACHMENTS INC",
					"contactName": "Darlene Ward",
					"phoneNumber": "5196993923",
					"email": "darlene.w@amiattachments.com"
				}
			},
			"lineItems": [
				{
					"freightClass": "70",
					"packageType": "CARTON",
					"totalWeight": 1000.0,
					"packageDimensions": {
						"length": 10.0,
						"width": 10.0,
						"height": 10.0
					},
					"totalPackages": 1,
					"totalPieces": 1,
					"description": "$scenario_name",
					"stackable": false
				}
			],
			"pickupWindow": {
				"date": "$(date -d 'tomorrow' +'%Y-%m-%d')",
				"startTime": "$(date -d 'tomorrow' +'%H:%M')",
				"endTime": "$(date -d 'tomorrow 6 hours' +'%H:%M')"
			},
			"deliveryWindow": {
				"date": "$(date -d '2 days' +'%Y-%m-%d')",
				"startTime": "$(date -d '2 days' +'%H:%M')",
				"endTime": "$(date -d '2 days 6 hours' +'%H:%M')"
			},
			"carrierCode": "$scac",
			"shipmentIdentifiers": [
				{
					"type": "CUSTOMER_REFERENCE",
					"value": "{$scac}_dispatch_test_{$scenario_number}_$(date +%s)"
				},
				{
					"type": "PURCHASE_ORDER",
					"value": "{$scac}_dispatch_test_{$scenario_number}_$(date +%s)"
				}
			],
			"accessorialServices": [
				{
					"code": "POISON"
				}
			],
			"pickupNote": "TOTAL 1 H/U",
			"emergencyContact": {},
			"capacityProviderQuoteNumber": "{$scac}_{$scenario_number}_$(date +%s)",
			"apiConfiguration": {
				"noteConfiguration": {
					"enableTruncation": true
				},
				"allowUnsupportedAccessorials": true,
				"pickupOnly": false
			}
		}
		EOF
		)
		curl_call=$(cat <<-EOF
			$curl_template '$request_data'
		EOF
		)
		
		if [ "$flg_generate_output" == "true" ]; then	
			echo "$curl_call" > "$(pwd)/$output_folder/${curl_call_scenario_file_prefix}_$scenario_number.txt"
		fi
		response=$(eval "$curl_call" | jq)
		dash_count=$(($total_status_output_length - ${#scenario_name} - ${#scenario_desc} - 1))
		dashes=$(printf '%*s' "$dash_count" | tr ' ' '-')
		if [ "$flg_use_quiet_mode" == "false" ]; then
			echo -e "$scenario_name $scenario_desc response:\n$(echo "$response" | jq)"
		else
			echo "$scenario_name $scenario_desc $dashes Status code: $(print_status_code "$response")"
		fi
	fi


	scenario_number="15-1"
	scenario_name="Scenario $scenario_number"
	scenario_desc="(service level: CNVPU)"
	if [[ ("$flg_all" == "true" || " ${scenarios_to_run[@]} " =~ " $scenario_number ") && ! " ${scenarios_to_exclude[@]} " =~ " $scenario_number " ]]; then
	
		request_data=$(cat <<-EOF
		{
			"weightUnit": "LB",
			"lengthUnit": "IN",
			"paymentTermsOverride": "PREPAID",
			"directionOverride": "SHIPPER",
			"capacityProviderAccountGroup": {
				"code": "$account_group",
				"accounts": [
					{
						"code": "$scac"
					}
				]
			},
			"originLocation": {
				"address": {
					"country": "CA",
					"postalCode": "N0B1X0",
					"addressLines": [
						"1270 Geddes St"
					],
					"city": "Hawkesville $scenario_name",
					"state": "ON"
				},
				"contact": {
					"companyName": "A M I ATTACHMENTS INC",
					"contactName": "Darlene Ward",
					"phoneNumber": "5196993923",
					"email": "darlene.w@amiattachments.com"
				}
			},
			"destinationLocation": {
				"address": {
					"country": "CA",
					"postalCode": "T5M 2S1",
					"addressLines": [
						"16116  -111 Avenue Northwest"
					],
					"city": "Edmonton $scenario_name",
					"state": "AB"
				},
				"contact": {
					"companyName": "SMS Equipment Inc.",
					"contactName": "AARON RYAN",
					"phoneNumber": "7804512630"
				}
			},
			"requesterLocation": {
				"address": {
					"country": "CA",
					"postalCode": "N0B1X0",
					"addressLines": [
						"1270 Geddes St"
					],
					"city": "Hawkesville $scenario_name",
					"state": "ON"
				},
				"contact": {
					"companyName": "A M I ATTACHMENTS INC",
					"contactName": "Darlene Ward",
					"phoneNumber": "5196993923",
					"email": "darlene.w@amiattachments.com"
				}
			},
			"lineItems": [
				{
					"freightClass": "70",
					"packageType": "CARTON",
					"totalWeight": 1000.0,
					"packageDimensions": {
						"length": 10.0,
						"width": 10.0,
						"height": 10.0
					},
					"totalPackages": 1,
					"totalPieces": 1,
					"description": "$scenario_name",
					"stackable": false
				}
			],
			"pickupWindow": {
				"date": "$(date -d 'tomorrow' +'%Y-%m-%d')",
				"startTime": "$(date -d 'tomorrow' +'%H:%M')",
				"endTime": "$(date -d 'tomorrow 6 hours' +'%H:%M')"
			},
			"deliveryWindow": {
				"date": "$(date -d '2 days' +'%Y-%m-%d')",
				"startTime": "$(date -d '2 days' +'%H:%M')",
				"endTime": "$(date -d '2 days 6 hours' +'%H:%M')"
			},
			"carrierCode": "$scac",
			"shipmentIdentifiers": [
				{
					"type": "CUSTOMER_REFERENCE",
					"value": "{$scac}_dispatch_test_{$scenario_number}_$(date +%s)"
				},
				{
					"type": "PURCHASE_ORDER",
					"value": "{$scac}_dispatch_test_{$scenario_number}_$(date +%s)"
				}
			],
			"accessorialServices": [
				{
					"code": "CNVPU"
				}
			],
			"pickupNote": "TOTAL 1 H/U",
			"emergencyContact": {},
			"capacityProviderQuoteNumber": "{$scac}_{$scenario_number}_$(date +%s)",
			"apiConfiguration": {
				"noteConfiguration": {
					"enableTruncation": true
				},
				"allowUnsupportedAccessorials": true,
				"pickupOnly": false
			}
		}
		EOF
		)
		curl_call=$(cat <<-EOF
			$curl_template '$request_data'
		EOF
		)
		
		if [ "$flg_generate_output" == "true" ]; then	
			echo "$curl_call" > "$(pwd)/$output_folder/${curl_call_scenario_file_prefix}_$scenario_number.txt"
		fi
		response=$(eval "$curl_call" | jq)
		dash_count=$(($total_status_output_length - ${#scenario_name} - ${#scenario_desc} - 1))
		dashes=$(printf '%*s' "$dash_count" | tr ' ' '-')
		if [ "$flg_use_quiet_mode" == "false" ]; then
			echo -e "$scenario_name $scenario_desc response:\n$(echo "$response" | jq)"
		else
			echo "$scenario_name $scenario_desc $dashes Status code: $(print_status_code "$response")"
		fi
	fi


	scenario_number="15-2"
	scenario_name="Scenario $scenario_number"
	scenario_desc="(service level: INPU)"
	if [[ ("$flg_all" == "true" || " ${scenarios_to_run[@]} " =~ " $scenario_number ") && ! " ${scenarios_to_exclude[@]} " =~ " $scenario_number " ]]; then
	
		request_data=$(cat <<-EOF
		{
			"weightUnit": "LB",
			"lengthUnit": "IN",
			"paymentTermsOverride": "PREPAID",
			"directionOverride": "SHIPPER",
			"capacityProviderAccountGroup": {
				"code": "$account_group",
				"accounts": [
					{
						"code": "$scac"
					}
				]
			},
			"originLocation": {
				"address": {
					"country": "CA",
					"postalCode": "N0B1X0",
					"addressLines": [
						"1270 Geddes St"
					],
					"city": "Hawkesville $scenario_name",
					"state": "ON"
				},
				"contact": {
					"companyName": "A M I ATTACHMENTS INC",
					"contactName": "Darlene Ward",
					"phoneNumber": "5196993923",
					"email": "darlene.w@amiattachments.com"
				}
			},
			"destinationLocation": {
				"address": {
					"country": "CA",
					"postalCode": "T5M 2S1",
					"addressLines": [
						"16116  -111 Avenue Northwest"
					],
					"city": "Edmonton $scenario_name",
					"state": "AB"
				},
				"contact": {
					"companyName": "SMS Equipment Inc.",
					"contactName": "AARON RYAN",
					"phoneNumber": "7804512630"
				}
			},
			"requesterLocation": {
				"address": {
					"country": "CA",
					"postalCode": "N0B1X0",
					"addressLines": [
						"1270 Geddes St"
					],
					"city": "Hawkesville $scenario_name",
					"state": "ON"
				},
				"contact": {
					"companyName": "A M I ATTACHMENTS INC",
					"contactName": "Darlene Ward",
					"phoneNumber": "5196993923",
					"email": "darlene.w@amiattachments.com"
				}
			},
			"lineItems": [
				{
					"freightClass": "70",
					"packageType": "CARTON",
					"totalWeight": 1000.0,
					"packageDimensions": {
						"length": 10.0,
						"width": 10.0,
						"height": 10.0
					},
					"totalPackages": 1,
					"totalPieces": 1,
					"description": "$scenario_name",
					"stackable": false
				}
			],
			"pickupWindow": {
				"date": "$(date -d 'tomorrow' +'%Y-%m-%d')",
				"startTime": "$(date -d 'tomorrow' +'%H:%M')",
				"endTime": "$(date -d 'tomorrow 6 hours' +'%H:%M')"
			},
			"deliveryWindow": {
				"date": "$(date -d '2 days' +'%Y-%m-%d')",
				"startTime": "$(date -d '2 days' +'%H:%M')",
				"endTime": "$(date -d '2 days 6 hours' +'%H:%M')"
			},
			"carrierCode": "$scac",
			"shipmentIdentifiers": [
				{
					"type": "CUSTOMER_REFERENCE",
					"value": "{$scac}_dispatch_test_{$scenario_number}_$(date +%s)"
				},
				{
					"type": "PURCHASE_ORDER",
					"value": "{$scac}_dispatch_test_{$scenario_number}_$(date +%s)"
				}
			],
			"accessorialServices": [
				{
					"code": "INPU"
				}
			],
			"pickupNote": "TOTAL 1 H/U",
			"emergencyContact": {},
			"capacityProviderQuoteNumber": "{$scac}_{$scenario_number}_$(date +%s)",
			"apiConfiguration": {
				"noteConfiguration": {
					"enableTruncation": true
				},
				"allowUnsupportedAccessorials": true,
				"pickupOnly": false
			}
		}
		EOF
		)
		curl_call=$(cat <<-EOF
			$curl_template '$request_data'
		EOF
		)
		
		if [ "$flg_generate_output" == "true" ]; then	
			echo "$curl_call" > "$(pwd)/$output_folder/${curl_call_scenario_file_prefix}_$scenario_number.txt"
		fi
		response=$(eval "$curl_call" | jq)
		dash_count=$(($total_status_output_length - ${#scenario_name} - ${#scenario_desc} - 1))
		dashes=$(printf '%*s' "$dash_count" | tr ' ' '-')
		if [ "$flg_use_quiet_mode" == "false" ]; then
			echo -e "$scenario_name $scenario_desc response:\n$(echo "$response" | jq)"
		else
			echo "$scenario_name $scenario_desc $dashes Status code: $(print_status_code "$response")"
		fi
	fi


	scenario_number="16-1"
	scenario_name="Scenario $scenario_number"
	scenario_desc="(accessorial code: LTDPU)"
	if [[ ("$flg_all" == "true" || " ${scenarios_to_run[@]} " =~ " $scenario_number ") && ! " ${scenarios_to_exclude[@]} " =~ " $scenario_number " ]]; then
	
		request_data=$(cat <<-EOF
		{
			"weightUnit": "LB",
			"lengthUnit": "IN",
			"paymentTermsOverride": "PREPAID",
			"directionOverride": "SHIPPER",
			"capacityProviderAccountGroup": {
				"code": "$account_group",
				"accounts": [
					{
						"code": "$scac"
					}
				]
			},
			"originLocation": {
				"address": {
					"country": "CA",
					"postalCode": "N0B1X0",
					"addressLines": [
						"1270 Geddes St"
					],
					"city": "Hawkesville $scenario_name",
					"state": "ON"
				},
				"contact": {
					"companyName": "A M I ATTACHMENTS INC",
					"contactName": "Darlene Ward",
					"phoneNumber": "5196993923",
					"email": "darlene.w@amiattachments.com"
				}
			},
			"destinationLocation": {
				"address": {
					"country": "CA",
					"postalCode": "T5M 2S1",
					"addressLines": [
						"16116  -111 Avenue Northwest"
					],
					"city": "Edmonton $scenario_name",
					"state": "AB"
				},
				"contact": {
					"companyName": "SMS Equipment Inc.",
					"contactName": "AARON RYAN",
					"phoneNumber": "7804512630"
				}
			},
			"requesterLocation": {
				"address": {
					"country": "CA",
					"postalCode": "N0B1X0",
					"addressLines": [
						"1270 Geddes St"
					],
					"city": "Hawkesville $scenario_name",
					"state": "ON"
				},
				"contact": {
					"companyName": "A M I ATTACHMENTS INC",
					"contactName": "Darlene Ward",
					"phoneNumber": "5196993923",
					"email": "darlene.w@amiattachments.com"
				}
			},
			"lineItems": [
				{
					"freightClass": "70",
					"packageType": "CARTON",
					"totalWeight": 1000.0,
					"packageDimensions": {
						"length": 10.0,
						"width": 10.0,
						"height": 10.0
					},
					"totalPackages": 1,
					"totalPieces": 1,
					"description": "$scenario_name",
					"stackable": false
				}
			],
			"pickupWindow": {
				"date": "$(date -d 'tomorrow' +'%Y-%m-%d')",
				"startTime": "$(date -d 'tomorrow' +'%H:%M')",
				"endTime": "$(date -d 'tomorrow 6 hours' +'%H:%M')"
			},
			"deliveryWindow": {
				"date": "$(date -d '2 days' +'%Y-%m-%d')",
				"startTime": "$(date -d '2 days' +'%H:%M')",
				"endTime": "$(date -d '2 days 6 hours' +'%H:%M')"
			},
			"carrierCode": "$scac",
			"shipmentIdentifiers": [
				{
					"type": "CUSTOMER_REFERENCE",
					"value": "{$scac}_dispatch_test_{$scenario_number}_$(date +%s)"
				},
				{
					"type": "PURCHASE_ORDER",
					"value": "{$scac}_dispatch_test_{$scenario_number}_$(date +%s)"
				}
			],
			"accessorialServices": [
				{
					"code": "LTDPU"
				}
			],
			"pickupNote": "TOTAL 1 H/U",
			"emergencyContact": {},
			"capacityProviderQuoteNumber": "{$scac}_{$scenario_number}_$(date +%s)",
			"apiConfiguration": {
				"noteConfiguration": {
					"enableTruncation": true
				},
				"allowUnsupportedAccessorials": true,
				"pickupOnly": false
			}
		}
		EOF
		)
		curl_call=$(cat <<-EOF
			$curl_template '$request_data'
		EOF
		)
		
		if [ "$flg_generate_output" == "true" ]; then	
			echo "$curl_call" > "$(pwd)/$output_folder/${curl_call_scenario_file_prefix}_$scenario_number.txt"
		fi
		response=$(eval "$curl_call" | jq)
		dash_count=$(($total_status_output_length - ${#scenario_name} - ${#scenario_desc} - 1))
		dashes=$(printf '%*s' "$dash_count" | tr ' ' '-')
		if [ "$flg_use_quiet_mode" == "false" ]; then
			echo -e "$scenario_name $scenario_desc response:\n$(echo "$response" | jq)"
		else
			echo "$scenario_name $scenario_desc $dashes Status code: $(print_status_code "$response")"
		fi
	fi


	scenario_number="16-2"
	scenario_name="Scenario $scenario_number"
	scenario_desc="(accessorial code: LTDDEL)"
	if [[ ("$flg_all" == "true" || " ${scenarios_to_run[@]} " =~ " $scenario_number ") && ! " ${scenarios_to_exclude[@]} " =~ " $scenario_number " ]]; then
	
		request_data=$(cat <<-EOF
		{
			"weightUnit": "LB",
			"lengthUnit": "IN",
			"paymentTermsOverride": "PREPAID",
			"directionOverride": "SHIPPER",
			"capacityProviderAccountGroup": {
				"code": "$account_group",
				"accounts": [
					{
						"code": "$scac"
					}
				]
			},
			"originLocation": {
				"address": {
					"country": "CA",
					"postalCode": "N0B1X0",
					"addressLines": [
						"1270 Geddes St"
					],
					"city": "Hawkesville $scenario_name",
					"state": "ON"
				},
				"contact": {
					"companyName": "A M I ATTACHMENTS INC",
					"contactName": "Darlene Ward",
					"phoneNumber": "5196993923",
					"email": "darlene.w@amiattachments.com"
				}
			},
			"destinationLocation": {
				"address": {
					"country": "CA",
					"postalCode": "T5M 2S1",
					"addressLines": [
						"16116  -111 Avenue Northwest"
					],
					"city": "Edmonton $scenario_name",
					"state": "AB"
				},
				"contact": {
					"companyName": "SMS Equipment Inc.",
					"contactName": "AARON RYAN",
					"phoneNumber": "7804512630"
				}
			},
			"requesterLocation": {
				"address": {
					"country": "CA",
					"postalCode": "N0B1X0",
					"addressLines": [
						"1270 Geddes St"
					],
					"city": "Hawkesville $scenario_name",
					"state": "ON"
				},
				"contact": {
					"companyName": "A M I ATTACHMENTS INC",
					"contactName": "Darlene Ward",
					"phoneNumber": "5196993923",
					"email": "darlene.w@amiattachments.com"
				}
			},
			"lineItems": [
				{
					"freightClass": "70",
					"packageType": "CARTON",
					"totalWeight": 1000.0,
					"packageDimensions": {
						"length": 10.0,
						"width": 10.0,
						"height": 10.0
					},
					"totalPackages": 1,
					"totalPieces": 1,
					"description": "$scenario_name",
					"stackable": false
				}
			],
			"pickupWindow": {
				"date": "$(date -d 'tomorrow' +'%Y-%m-%d')",
				"startTime": "$(date -d 'tomorrow' +'%H:%M')",
				"endTime": "$(date -d 'tomorrow 6 hours' +'%H:%M')"
			},
			"deliveryWindow": {
				"date": "$(date -d '2 days' +'%Y-%m-%d')",
				"startTime": "$(date -d '2 days' +'%H:%M')",
				"endTime": "$(date -d '2 days 6 hours' +'%H:%M')"
			},
			"carrierCode": "$scac",
			"shipmentIdentifiers": [
				{
					"type": "CUSTOMER_REFERENCE",
					"value": "{$scac}_dispatch_test_{$scenario_number}_$(date +%s)"
				},
				{
					"type": "PURCHASE_ORDER",
					"value": "{$scac}_dispatch_test_{$scenario_number}_$(date +%s)"
				}
			],
			"accessorialServices": [
				{
					"code": "LTDDEL"
				}
			],
			"pickupNote": "TOTAL 1 H/U",
			"emergencyContact": {},
			"capacityProviderQuoteNumber": "{$scac}_{$scenario_number}_$(date +%s)",
			"apiConfiguration": {
				"noteConfiguration": {
					"enableTruncation": true
				},
				"allowUnsupportedAccessorials": true,
				"pickupOnly": false
			}
		}
		EOF
		)
		curl_call=$(cat <<-EOF
			$curl_template '$request_data'
		EOF
		)
		
		if [ "$flg_generate_output" == "true" ]; then	
			echo "$curl_call" > "$(pwd)/$output_folder/${curl_call_scenario_file_prefix}_$scenario_number.txt"
		fi
		response=$(eval "$curl_call" | jq)
		dash_count=$(($total_status_output_length - ${#scenario_name} - ${#scenario_desc} - 1))
		dashes=$(printf '%*s' "$dash_count" | tr ' ' '-')
		if [ "$flg_use_quiet_mode" == "false" ]; then
			echo -e "$scenario_name $scenario_desc response:\n$(echo "$response" | jq)"
		else
			echo "$scenario_name $scenario_desc $dashes Status code: $(print_status_code "$response")"
		fi
	fi


	scenario_number="17-1"
	scenario_name="Scenario $scenario_number"
	scenario_desc="(1 line item)"
	if [[ ("$flg_all" == "true" || " ${scenarios_to_run[@]} " =~ " $scenario_number ") && ! " ${scenarios_to_exclude[@]} " =~ " $scenario_number " ]]; then
	
		request_data=$(cat <<-EOF
		{
			"weightUnit": "LB",
			"lengthUnit": "IN",
			"paymentTermsOverride": "PREPAID",
			"directionOverride": "SHIPPER",
			"capacityProviderAccountGroup": {
				"code": "$account_group",
				"accounts": [
					{
						"code": "$scac"
					}
				]
			},
			"originLocation": {
				"address": {
					"country": "CA",
					"postalCode": "N0B1X0",
					"addressLines": [
						"1270 Geddes St"
					],
					"city": "Hawkesville $scenario_name",
					"state": "ON"
				},
				"contact": {
					"companyName": "A M I ATTACHMENTS INC",
					"contactName": "Darlene Ward",
					"phoneNumber": "5196993923",
					"email": "darlene.w@amiattachments.com"
				}
			},
			"destinationLocation": {
				"address": {
					"country": "CA",
					"postalCode": "T5M 2S1",
					"addressLines": [
						"16116  -111 Avenue Northwest"
					],
					"city": "Edmonton $scenario_name",
					"state": "AB"
				},
				"contact": {
					"companyName": "SMS Equipment Inc.",
					"contactName": "AARON RYAN",
					"phoneNumber": "7804512630"
				}
			},
			"requesterLocation": {
				"address": {
					"country": "CA",
					"postalCode": "N0B1X0",
					"addressLines": [
						"1270 Geddes St"
					],
					"city": "Hawkesville $scenario_name",
					"state": "ON"
				},
				"contact": {
					"companyName": "A M I ATTACHMENTS INC",
					"contactName": "Darlene Ward",
					"phoneNumber": "5196993923",
					"email": "darlene.w@amiattachments.com"
				}
			},
			"lineItems": [
				{
					"freightClass": "70",
					"packageType": "CARTON",
					"totalWeight": 1000.0,
					"packageDimensions": {
						"length": 10.0,
						"width": 10.0,
						"height": 10.0
					},
					"totalPackages": 1,
					"totalPieces": 1,
					"description": "$scenario_name",
					"stackable": false
				}
			],
			"pickupWindow": {
				"date": "$(date -d 'tomorrow' +'%Y-%m-%d')",
				"startTime": "$(date -d 'tomorrow' +'%H:%M')",
				"endTime": "$(date -d 'tomorrow 6 hours' +'%H:%M')"
			},
			"deliveryWindow": {
				"date": "$(date -d '2 days' +'%Y-%m-%d')",
				"startTime": "$(date -d '2 days' +'%H:%M')",
				"endTime": "$(date -d '2 days 6 hours' +'%H:%M')"
			},
			"carrierCode": "$scac",
			"shipmentIdentifiers": [
				{
					"type": "CUSTOMER_REFERENCE",
					"value": "{$scac}_dispatch_test_{$scenario_number}_$(date +%s)"
				},
				{
					"type": "PURCHASE_ORDER",
					"value": "{$scac}_dispatch_test_{$scenario_number}_$(date +%s)"
				}
			],
			"accessorialServices": [],
			"pickupNote": "TOTAL 1 H/U",
			"emergencyContact": {},
			"capacityProviderQuoteNumber": "{$scac}_{$scenario_number}_$(date +%s)",
			"apiConfiguration": {
				"noteConfiguration": {
					"enableTruncation": true
				},
				"allowUnsupportedAccessorials": true,
				"pickupOnly": false
			}
		}
		EOF
		)
		curl_call=$(cat <<-EOF
			$curl_template '$request_data'
		EOF
		)
		
		if [ "$flg_generate_output" == "true" ]; then	
			echo "$curl_call" > "$(pwd)/$output_folder/${curl_call_scenario_file_prefix}_$scenario_number.txt"
		fi
		response=$(eval "$curl_call" | jq)
		dash_count=$(($total_status_output_length - ${#scenario_name} - ${#scenario_desc} - 1))
		dashes=$(printf '%*s' "$dash_count" | tr ' ' '-')
		if [ "$flg_use_quiet_mode" == "false" ]; then
			echo -e "$scenario_name $scenario_desc response:\n$(echo "$response" | jq)"
		else
			echo "$scenario_name $scenario_desc $dashes Status code: $(print_status_code "$response")"
		fi
	fi


	scenario_number="17-2"
	scenario_name="Scenario $scenario_number"
	scenario_desc="(5 line items)"
	if [[ ("$flg_all" == "true" || " ${scenarios_to_run[@]} " =~ " $scenario_number ") && ! " ${scenarios_to_exclude[@]} " =~ " $scenario_number " ]]; then
	
		request_data=$(cat <<-EOF
		{
			"weightUnit": "LB",
			"lengthUnit": "IN",
			"paymentTermsOverride": "PREPAID",
			"directionOverride": "SHIPPER",
			"capacityProviderAccountGroup": {
				"code": "$account_group",
				"accounts": [
					{
						"code": "$scac"
					}
				]
			},
			"originLocation": {
				"address": {
					"country": "CA",
					"postalCode": "N0B1X0",
					"addressLines": [
						"1270 Geddes St"
					],
					"city": "Hawkesville $scenario_name",
					"state": "ON"
				},
				"contact": {
					"companyName": "A M I ATTACHMENTS INC",
					"contactName": "Darlene Ward",
					"phoneNumber": "5196993923",
					"email": "darlene.w@amiattachments.com"
				}
			},
			"destinationLocation": {
				"address": {
					"country": "CA",
					"postalCode": "T5M 2S1",
					"addressLines": [
						"16116  -111 Avenue Northwest"
					],
					"city": "Edmonton $scenario_name",
					"state": "AB"
				},
				"contact": {
					"companyName": "SMS Equipment Inc.",
					"contactName": "AARON RYAN",
					"phoneNumber": "7804512630"
				}
			},
			"requesterLocation": {
				"address": {
					"country": "CA",
					"postalCode": "N0B1X0",
					"addressLines": [
						"1270 Geddes St"
					],
					"city": "Hawkesville $scenario_name",
					"state": "ON"
				},
				"contact": {
					"companyName": "A M I ATTACHMENTS INC",
					"contactName": "Darlene Ward",
					"phoneNumber": "5196993923",
					"email": "darlene.w@amiattachments.com"
				}
			},
			"lineItems": [
				{
					"freightClass": "70",
					"packageType": "CARTON",
					"totalWeight": 1000.0,
					"packageDimensions": {
						"length": 10.0,
						"width": 10.0,
						"height": 10.0
					},
					"totalPackages": 1,
					"totalPieces": 1,
					"description": "$scenario_name",
					"stackable": false
				},
				{
					"freightClass": "70",
					"packageType": "CARTON",
					"totalWeight": 1000.0,
					"packageDimensions": {
						"length": 10.0,
						"width": 10.0,
						"height": 10.0
					},
					"totalPackages": 1,
					"totalPieces": 1,
					"description": "$scenario_name",
					"stackable": false
				},
				{
					"freightClass": "70",
					"packageType": "CARTON",
					"totalWeight": 1000.0,
					"packageDimensions": {
						"length": 10.0,
						"width": 10.0,
						"height": 10.0
					},
					"totalPackages": 1,
					"totalPieces": 1,
					"description": "$scenario_name",
					"stackable": false
				},
				{
					"freightClass": "70",
					"packageType": "CARTON",
					"totalWeight": 1000.0,
					"packageDimensions": {
						"length": 10.0,
						"width": 10.0,
						"height": 10.0
					},
					"totalPackages": 1,
					"totalPieces": 1,
					"description": "$scenario_name",
					"stackable": false
				},
				{
					"freightClass": "70",
					"packageType": "CARTON",
					"totalWeight": 1000.0,
					"packageDimensions": {
						"length": 10.0,
						"width": 10.0,
						"height": 10.0
					},
					"totalPackages": 1,
					"totalPieces": 1,
					"description": "$scenario_name",
					"stackable": false
				}
			],
			"pickupWindow": {
				"date": "$(date -d 'tomorrow' +'%Y-%m-%d')",
				"startTime": "$(date -d 'tomorrow' +'%H:%M')",
				"endTime": "$(date -d 'tomorrow 6 hours' +'%H:%M')"
			},
			"deliveryWindow": {
				"date": "$(date -d '2 days' +'%Y-%m-%d')",
				"startTime": "$(date -d '2 days' +'%H:%M')",
				"endTime": "$(date -d '2 days 6 hours' +'%H:%M')"
			},
			"carrierCode": "$scac",
			"shipmentIdentifiers": [
				{
					"type": "CUSTOMER_REFERENCE",
					"value": "{$scac}_dispatch_test_{$scenario_number}_$(date +%s)"
				},
				{
					"type": "PURCHASE_ORDER",
					"value": "{$scac}_dispatch_test_{$scenario_number}_$(date +%s)"
				}
			],
			"accessorialServices": [],
			"pickupNote": "TOTAL 1 H/U",
			"emergencyContact": {},
			"capacityProviderQuoteNumber": "{$scac}_{$scenario_number}_$(date +%s)",
			"apiConfiguration": {
				"noteConfiguration": {
					"enableTruncation": true
				},
				"allowUnsupportedAccessorials": true,
				"pickupOnly": false
			}
		}
		EOF
		)
		curl_call=$(cat <<-EOF
			$curl_template '$request_data'
		EOF
		)
		
		if [ "$flg_generate_output" == "true" ]; then	
			echo "$curl_call" > "$(pwd)/$output_folder/${curl_call_scenario_file_prefix}_$scenario_number.txt"
		fi
		response=$(eval "$curl_call" | jq)
		dash_count=$(($total_status_output_length - ${#scenario_name} - ${#scenario_desc} - 1))
		dashes=$(printf '%*s' "$dash_count" | tr ' ' '-')
		if [ "$flg_use_quiet_mode" == "false" ]; then
			echo -e "$scenario_name $scenario_desc response:\n$(echo "$response" | jq)"
		else
			echo "$scenario_name $scenario_desc $dashes Status code: $(print_status_code "$response")"
		fi
	fi


	scenario_number="17-3"
	scenario_name="Scenario $scenario_number"
	scenario_desc="(10 line items)"
	if [[ ("$flg_all" == "true" || " ${scenarios_to_run[@]} " =~ " $scenario_number ") && ! " ${scenarios_to_exclude[@]} " =~ " $scenario_number " ]]; then
	
		request_data=$(cat <<-EOF
		{
			"weightUnit": "LB",
			"lengthUnit": "IN",
			"paymentTermsOverride": "PREPAID",
			"directionOverride": "SHIPPER",
			"capacityProviderAccountGroup": {
				"code": "$account_group",
				"accounts": [
					{
						"code": "$scac"
					}
				]
			},
			"originLocation": {
				"address": {
					"country": "CA",
					"postalCode": "N0B1X0",
					"addressLines": [
						"1270 Geddes St"
					],
					"city": "Hawkesville $scenario_name",
					"state": "ON"
				},
				"contact": {
					"companyName": "A M I ATTACHMENTS INC",
					"contactName": "Darlene Ward",
					"phoneNumber": "5196993923",
					"email": "darlene.w@amiattachments.com"
				}
			},
			"destinationLocation": {
				"address": {
					"country": "CA",
					"postalCode": "T5M 2S1",
					"addressLines": [
						"16116  -111 Avenue Northwest"
					],
					"city": "Edmonton $scenario_name",
					"state": "AB"
				},
				"contact": {
					"companyName": "SMS Equipment Inc.",
					"contactName": "AARON RYAN",
					"phoneNumber": "7804512630"
				}
			},
			"requesterLocation": {
				"address": {
					"country": "CA",
					"postalCode": "N0B1X0",
					"addressLines": [
						"1270 Geddes St"
					],
					"city": "Hawkesville $scenario_name",
					"state": "ON"
				},
				"contact": {
					"companyName": "A M I ATTACHMENTS INC",
					"contactName": "Darlene Ward",
					"phoneNumber": "5196993923",
					"email": "darlene.w@amiattachments.com"
				}
			},
			"lineItems": [
				{
					"freightClass": "70",
					"packageType": "CARTON",
					"totalWeight": 1000.0,
					"packageDimensions": {
						"length": 10.0,
						"width": 10.0,
						"height": 10.0
					},
					"totalPackages": 1,
					"totalPieces": 1,
					"description": "$scenario_name",
					"stackable": false
				},
				{
					"freightClass": "70",
					"packageType": "CARTON",
					"totalWeight": 1000.0,
					"packageDimensions": {
						"length": 10.0,
						"width": 10.0,
						"height": 10.0
					},
					"totalPackages": 1,
					"totalPieces": 1,
					"description": "$scenario_name",
					"stackable": false
				},
				{
					"freightClass": "70",
					"packageType": "CARTON",
					"totalWeight": 1000.0,
					"packageDimensions": {
						"length": 10.0,
						"width": 10.0,
						"height": 10.0
					},
					"totalPackages": 1,
					"totalPieces": 1,
					"description": "$scenario_name",
					"stackable": false
				},
				{
					"freightClass": "70",
					"packageType": "CARTON",
					"totalWeight": 1000.0,
					"packageDimensions": {
						"length": 10.0,
						"width": 10.0,
						"height": 10.0
					},
					"totalPackages": 1,
					"totalPieces": 1,
					"description": "$scenario_name",
					"stackable": false
				},
				{
					"freightClass": "70",
					"packageType": "CARTON",
					"totalWeight": 1000.0,
					"packageDimensions": {
						"length": 10.0,
						"width": 10.0,
						"height": 10.0
					},
					"totalPackages": 1,
					"totalPieces": 1,
					"description": "$scenario_name",
					"stackable": false
				},
				{
					"freightClass": "70",
					"packageType": "CARTON",
					"totalWeight": 1000.0,
					"packageDimensions": {
						"length": 10.0,
						"width": 10.0,
						"height": 10.0
					},
					"totalPackages": 1,
					"totalPieces": 1,
					"description": "$scenario_name",
					"stackable": false
				},
				{
					"freightClass": "70",
					"packageType": "CARTON",
					"totalWeight": 1000.0,
					"packageDimensions": {
						"length": 10.0,
						"width": 10.0,
						"height": 10.0
					},
					"totalPackages": 1,
					"totalPieces": 1,
					"description": "$scenario_name",
					"stackable": false
				},
				{
					"freightClass": "70",
					"packageType": "CARTON",
					"totalWeight": 1000.0,
					"packageDimensions": {
						"length": 10.0,
						"width": 10.0,
						"height": 10.0
					},
					"totalPackages": 1,
					"totalPieces": 1,
					"description": "$scenario_name",
					"stackable": false
				},
				{
					"freightClass": "70",
					"packageType": "CARTON",
					"totalWeight": 1000.0,
					"packageDimensions": {
						"length": 10.0,
						"width": 10.0,
						"height": 10.0
					},
					"totalPackages": 1,
					"totalPieces": 1,
					"description": "$scenario_name",
					"stackable": false
				},
				{
					"freightClass": "70",
					"packageType": "CARTON",
					"totalWeight": 1000.0,
					"packageDimensions": {
						"length": 10.0,
						"width": 10.0,
						"height": 10.0
					},
					"totalPackages": 1,
					"totalPieces": 1,
					"description": "$scenario_name",
					"stackable": false
				}
			],
			"pickupWindow": {
				"date": "$(date -d 'tomorrow' +'%Y-%m-%d')",
				"startTime": "$(date -d 'tomorrow' +'%H:%M')",
				"endTime": "$(date -d 'tomorrow 6 hours' +'%H:%M')"
			},
			"deliveryWindow": {
				"date": "$(date -d '2 days' +'%Y-%m-%d')",
				"startTime": "$(date -d '2 days' +'%H:%M')",
				"endTime": "$(date -d '2 days 6 hours' +'%H:%M')"
			},
			"carrierCode": "$scac",
			"shipmentIdentifiers": [
				{
					"type": "CUSTOMER_REFERENCE",
					"value": "{$scac}_dispatch_test_{$scenario_number}_$(date +%s)"
				},
				{
					"type": "PURCHASE_ORDER",
					"value": "{$scac}_dispatch_test_{$scenario_number}_$(date +%s)"
				}
			],
			"accessorialServices": [],
			"pickupNote": "TOTAL 1 H/U",
			"emergencyContact": {},
			"capacityProviderQuoteNumber": "{$scac}_{$scenario_number}_$(date +%s)",
			"apiConfiguration": {
				"noteConfiguration": {
					"enableTruncation": true
				},
				"allowUnsupportedAccessorials": true,
				"pickupOnly": false
			}
		}
		EOF
		)
		curl_call=$(cat <<-EOF
			$curl_template '$request_data'
		EOF
		)
		
		if [ "$flg_generate_output" == "true" ]; then	
			echo "$curl_call" > "$(pwd)/$output_folder/${curl_call_scenario_file_prefix}_$scenario_number.txt"
		fi
		response=$(eval "$curl_call" | jq)
		dash_count=$(($total_status_output_length - ${#scenario_name} - ${#scenario_desc} - 1))
		dashes=$(printf '%*s' "$dash_count" | tr ' ' '-')
		if [ "$flg_use_quiet_mode" == "false" ]; then
			echo -e "$scenario_name $scenario_desc response:\n$(echo "$response" | jq)"
		else
			echo "$scenario_name $scenario_desc $dashes Status code: $(print_status_code "$response")"
		fi
	fi


	scenario_number="18-1"
	scenario_name="Scenario $scenario_number"
	scenario_desc="(stackable: true)"
	if [[ ("$flg_all" == "true" || " ${scenarios_to_run[@]} " =~ " $scenario_number ") && ! " ${scenarios_to_exclude[@]} " =~ " $scenario_number " ]]; then
	
		request_data=$(cat <<-EOF
		{
			"weightUnit": "LB",
			"lengthUnit": "IN",
			"paymentTermsOverride": "PREPAID",
			"directionOverride": "SHIPPER",
			"capacityProviderAccountGroup": {
				"code": "$account_group",
				"accounts": [
					{
						"code": "$scac"
					}
				]
			},
			"originLocation": {
				"address": {
					"country": "CA",
					"postalCode": "N0B1X0",
					"addressLines": [
						"1270 Geddes St"
					],
					"city": "Hawkesville $scenario_name",
					"state": "ON"
				},
				"contact": {
					"companyName": "A M I ATTACHMENTS INC",
					"contactName": "Darlene Ward",
					"phoneNumber": "5196993923",
					"email": "darlene.w@amiattachments.com"
				}
			},
			"destinationLocation": {
				"address": {
					"country": "CA",
					"postalCode": "T5M 2S1",
					"addressLines": [
						"16116  -111 Avenue Northwest"
					],
					"city": "Edmonton $scenario_name",
					"state": "AB"
				},
				"contact": {
					"companyName": "SMS Equipment Inc.",
					"contactName": "AARON RYAN",
					"phoneNumber": "7804512630"
				}
			},
			"requesterLocation": {
				"address": {
					"country": "CA",
					"postalCode": "N0B1X0",
					"addressLines": [
						"1270 Geddes St"
					],
					"city": "Hawkesville $scenario_name",
					"state": "ON"
				},
				"contact": {
					"companyName": "A M I ATTACHMENTS INC",
					"contactName": "Darlene Ward",
					"phoneNumber": "5196993923",
					"email": "darlene.w@amiattachments.com"
				}
			},
			"lineItems": [
				{
					"freightClass": "70",
					"packageType": "CARTON",
					"totalWeight": 1000.0,
					"packageDimensions": {
						"length": 10.0,
						"width": 10.0,
						"height": 10.0
					},
					"totalPackages": 1,
					"totalPieces": 1,
					"description": "$scenario_name",
					"stackable": true
				},
				{
					"freightClass": "70",
					"packageType": "CARTON",
					"totalWeight": 1000.0,
					"packageDimensions": {
						"length": 10.0,
						"width": 10.0,
						"height": 10.0
					},
					"totalPackages": 1,
					"totalPieces": 1,
					"description": "$scenario_name",
					"stackable": true
				},
				{
					"freightClass": "70",
					"packageType": "CARTON",
					"totalWeight": 1000.0,
					"packageDimensions": {
						"length": 10.0,
						"width": 10.0,
						"height": 10.0
					},
					"totalPackages": 1,
					"totalPieces": 1,
					"description": "$scenario_name",
					"stackable": true
				},
				{
					"freightClass": "70",
					"packageType": "CARTON",
					"totalWeight": 1000.0,
					"packageDimensions": {
						"length": 10.0,
						"width": 10.0,
						"height": 10.0
					},
					"totalPackages": 1,
					"totalPieces": 1,
					"description": "$scenario_name",
					"stackable": true
				},
				{
					"freightClass": "70",
					"packageType": "CARTON",
					"totalWeight": 1000.0,
					"packageDimensions": {
						"length": 10.0,
						"width": 10.0,
						"height": 10.0
					},
					"totalPackages": 1,
					"totalPieces": 1,
					"description": "$scenario_name",
					"stackable": true
				},
				{
					"freightClass": "70",
					"packageType": "CARTON",
					"totalWeight": 1000.0,
					"packageDimensions": {
						"length": 10.0,
						"width": 10.0,
						"height": 10.0
					},
					"totalPackages": 1,
					"totalPieces": 1,
					"description": "$scenario_name",
					"stackable": true
				}
			],
			"pickupWindow": {
				"date": "$(date -d 'tomorrow' +'%Y-%m-%d')",
				"startTime": "$(date -d 'tomorrow' +'%H:%M')",
				"endTime": "$(date -d 'tomorrow 6 hours' +'%H:%M')"
			},
			"deliveryWindow": {
				"date": "$(date -d '2 days' +'%Y-%m-%d')",
				"startTime": "$(date -d '2 days' +'%H:%M')",
				"endTime": "$(date -d '2 days 6 hours' +'%H:%M')"
			},
			"carrierCode": "$scac",
			"shipmentIdentifiers": [
				{
					"type": "CUSTOMER_REFERENCE",
					"value": "{$scac}_dispatch_test_{$scenario_number}_$(date +%s)"
				},
				{
					"type": "PURCHASE_ORDER",
					"value": "{$scac}_dispatch_test_{$scenario_number}_$(date +%s)"
				}
			],
			"accessorialServices": [],
			"pickupNote": "TOTAL 1 H/U",
			"emergencyContact": {},
			"capacityProviderQuoteNumber": "{$scac}_{$scenario_number}_$(date +%s)",
			"apiConfiguration": {
				"noteConfiguration": {
					"enableTruncation": true
				},
				"allowUnsupportedAccessorials": true,
				"pickupOnly": false
			}
		}
		EOF
		)
		curl_call=$(cat <<-EOF
			$curl_template '$request_data'
		EOF
		)
		
		if [ "$flg_generate_output" == "true" ]; then	
			echo "$curl_call" > "$(pwd)/$output_folder/${curl_call_scenario_file_prefix}_$scenario_number.txt"
		fi
		response=$(eval "$curl_call" | jq)
		dash_count=$(($total_status_output_length - ${#scenario_name} - ${#scenario_desc} - 1))
		dashes=$(printf '%*s' "$dash_count" | tr ' ' '-')
		if [ "$flg_use_quiet_mode" == "false" ]; then
			echo -e "$scenario_name $scenario_desc response:\n$(echo "$response" | jq)"
		else
			echo "$scenario_name $scenario_desc $dashes Status code: $(print_status_code "$response")"
		fi
	fi


	scenario_number="18-2"
	scenario_name="Scenario $scenario_number"
	scenario_desc="(stackable: false)"
	if [[ ("$flg_all" == "true" || " ${scenarios_to_run[@]} " =~ " $scenario_number ") && ! " ${scenarios_to_exclude[@]} " =~ " $scenario_number " ]]; then
	
		request_data=$(cat <<-EOF
		{
			"weightUnit": "LB",
			"lengthUnit": "IN",
			"paymentTermsOverride": "PREPAID",
			"directionOverride": "SHIPPER",
			"capacityProviderAccountGroup": {
				"code": "$account_group",
				"accounts": [
					{
						"code": "$scac"
					}
				]
			},
			"originLocation": {
				"address": {
					"country": "CA",
					"postalCode": "N0B1X0",
					"addressLines": [
						"1270 Geddes St"
					],
					"city": "Hawkesville $scenario_name",
					"state": "ON"
				},
				"contact": {
					"companyName": "A M I ATTACHMENTS INC",
					"contactName": "Darlene Ward",
					"phoneNumber": "5196993923",
					"email": "darlene.w@amiattachments.com"
				}
			},
			"destinationLocation": {
				"address": {
					"country": "CA",
					"postalCode": "T5M 2S1",
					"addressLines": [
						"16116  -111 Avenue Northwest"
					],
					"city": "Edmonton $scenario_name",
					"state": "AB"
				},
				"contact": {
					"companyName": "SMS Equipment Inc.",
					"contactName": "AARON RYAN",
					"phoneNumber": "7804512630"
				}
			},
			"requesterLocation": {
				"address": {
					"country": "CA",
					"postalCode": "N0B1X0",
					"addressLines": [
						"1270 Geddes St"
					],
					"city": "Hawkesville $scenario_name",
					"state": "ON"
				},
				"contact": {
					"companyName": "A M I ATTACHMENTS INC",
					"contactName": "Darlene Ward",
					"phoneNumber": "5196993923",
					"email": "darlene.w@amiattachments.com"
				}
			},
			"lineItems": [
				{
					"freightClass": "70",
					"packageType": "CARTON",
					"totalWeight": 1000.0,
					"packageDimensions": {
						"length": 10.0,
						"width": 10.0,
						"height": 10.0
					},
					"totalPackages": 1,
					"totalPieces": 1,
					"description": "$scenario_name",
					"stackable": false
				},
				{
					"freightClass": "70",
					"packageType": "CARTON",
					"totalWeight": 1000.0,
					"packageDimensions": {
						"length": 10.0,
						"width": 10.0,
						"height": 10.0
					},
					"totalPackages": 1,
					"totalPieces": 1,
					"description": "$scenario_name",
					"stackable": false
				},
				{
					"freightClass": "70",
					"packageType": "CARTON",
					"totalWeight": 1000.0,
					"packageDimensions": {
						"length": 10.0,
						"width": 10.0,
						"height": 10.0
					},
					"totalPackages": 1,
					"totalPieces": 1,
					"description": "$scenario_name",
					"stackable": false
				},
				{
					"freightClass": "70",
					"packageType": "CARTON",
					"totalWeight": 1000.0,
					"packageDimensions": {
						"length": 10.0,
						"width": 10.0,
						"height": 10.0
					},
					"totalPackages": 1,
					"totalPieces": 1,
					"description": "$scenario_name",
					"stackable": false
				},
				{
					"freightClass": "70",
					"packageType": "CARTON",
					"totalWeight": 1000.0,
					"packageDimensions": {
						"length": 10.0,
						"width": 10.0,
						"height": 10.0
					},
					"totalPackages": 1,
					"totalPieces": 1,
					"description": "$scenario_name",
					"stackable": false
				},
				{
					"freightClass": "70",
					"packageType": "CARTON",
					"totalWeight": 1000.0,
					"packageDimensions": {
						"length": 10.0,
						"width": 10.0,
						"height": 10.0
					},
					"totalPackages": 1,
					"totalPieces": 1,
					"description": "$scenario_name",
					"stackable": false
				}
			],
			"pickupWindow": {
				"date": "$(date -d 'tomorrow' +'%Y-%m-%d')",
				"startTime": "$(date -d 'tomorrow' +'%H:%M')",
				"endTime": "$(date -d 'tomorrow 6 hours' +'%H:%M')"
			},
			"deliveryWindow": {
				"date": "$(date -d '2 days' +'%Y-%m-%d')",
				"startTime": "$(date -d '2 days' +'%H:%M')",
				"endTime": "$(date -d '2 days 6 hours' +'%H:%M')"
			},
			"carrierCode": "$scac",
			"shipmentIdentifiers": [
				{
					"type": "CUSTOMER_REFERENCE",
					"value": "{$scac}_dispatch_test_{$scenario_number}_$(date +%s)"
				},
				{
					"type": "PURCHASE_ORDER",
					"value": "{$scac}_dispatch_test_{$scenario_number}_$(date +%s)"
				}
			],
			"accessorialServices": [],
			"pickupNote": "TOTAL 1 H/U",
			"emergencyContact": {},
			"capacityProviderQuoteNumber": "{$scac}_{$scenario_number}_$(date +%s)",
			"apiConfiguration": {
				"noteConfiguration": {
					"enableTruncation": true
				},
				"allowUnsupportedAccessorials": true,
				"pickupOnly": false
			}
		}
		EOF
		)
		curl_call=$(cat <<-EOF
			$curl_template '$request_data'
		EOF
		)
		
		if [ "$flg_generate_output" == "true" ]; then	
			echo "$curl_call" > "$(pwd)/$output_folder/${curl_call_scenario_file_prefix}_$scenario_number.txt"
		fi
		response=$(eval "$curl_call" | jq)
		dash_count=$(($total_status_output_length - ${#scenario_name} - ${#scenario_desc} - 1))
		dashes=$(printf '%*s' "$dash_count" | tr ' ' '-')
		if [ "$flg_use_quiet_mode" == "false" ]; then
			echo -e "$scenario_name $scenario_desc response:\n$(echo "$response" | jq)"
		else
			echo "$scenario_name $scenario_desc $dashes Status code: $(print_status_code "$response")"
		fi
	fi


	scenario_number="18-3"
	scenario_name="Scenario $scenario_number"
	scenario_desc="(stackable: mixed)"
	if [[ ("$flg_all" == "true" || " ${scenarios_to_run[@]} " =~ " $scenario_number ") && ! " ${scenarios_to_exclude[@]} " =~ " $scenario_number " ]]; then
	
		request_data=$(cat <<-EOF
		{
			"weightUnit": "LB",
			"lengthUnit": "IN",
			"paymentTermsOverride": "PREPAID",
			"directionOverride": "SHIPPER",
			"capacityProviderAccountGroup": {
				"code": "$account_group",
				"accounts": [
					{
						"code": "$scac"
					}
				]
			},
			"originLocation": {
				"address": {
					"country": "CA",
					"postalCode": "N0B1X0",
					"addressLines": [
						"1270 Geddes St"
					],
					"city": "Hawkesville $scenario_name",
					"state": "ON"
				},
				"contact": {
					"companyName": "A M I ATTACHMENTS INC",
					"contactName": "Darlene Ward",
					"phoneNumber": "5196993923",
					"email": "darlene.w@amiattachments.com"
				}
			},
			"destinationLocation": {
				"address": {
					"country": "CA",
					"postalCode": "T5M 2S1",
					"addressLines": [
						"16116  -111 Avenue Northwest"
					],
					"city": "Edmonton $scenario_name",
					"state": "AB"
				},
				"contact": {
					"companyName": "SMS Equipment Inc.",
					"contactName": "AARON RYAN",
					"phoneNumber": "7804512630"
				}
			},
			"requesterLocation": {
				"address": {
					"country": "CA",
					"postalCode": "N0B1X0",
					"addressLines": [
						"1270 Geddes St"
					],
					"city": "Hawkesville $scenario_name",
					"state": "ON"
				},
				"contact": {
					"companyName": "A M I ATTACHMENTS INC",
					"contactName": "Darlene Ward",
					"phoneNumber": "5196993923",
					"email": "darlene.w@amiattachments.com"
				}
			},
			"lineItems": [
				{
					"freightClass": "70",
					"packageType": "CARTON",
					"totalWeight": 1000.0,
					"packageDimensions": {
						"length": 10.0,
						"width": 10.0,
						"height": 10.0
					},
					"totalPackages": 1,
					"totalPieces": 1,
					"description": "$scenario_name",
					"stackable": false
				},
				{
					"freightClass": "70",
					"packageType": "CARTON",
					"totalWeight": 1000.0,
					"packageDimensions": {
						"length": 10.0,
						"width": 10.0,
						"height": 10.0
					},
					"totalPackages": 1,
					"totalPieces": 1,
					"description": "$scenario_name",
					"stackable": true
				},
				{
					"freightClass": "70",
					"packageType": "CARTON",
					"totalWeight": 1000.0,
					"packageDimensions": {
						"length": 10.0,
						"width": 10.0,
						"height": 10.0
					},
					"totalPackages": 1,
					"totalPieces": 1,
					"description": "$scenario_name",
					"stackable": false
				},
				{
					"freightClass": "70",
					"packageType": "CARTON",
					"totalWeight": 1000.0,
					"packageDimensions": {
						"length": 10.0,
						"width": 10.0,
						"height": 10.0
					},
					"totalPackages": 1,
					"totalPieces": 1,
					"description": "$scenario_name",
					"stackable": false
				},
				{
					"freightClass": "70",
					"packageType": "CARTON",
					"totalWeight": 1000.0,
					"packageDimensions": {
						"length": 10.0,
						"width": 10.0,
						"height": 10.0
					},
					"totalPackages": 1,
					"totalPieces": 1,
					"description": "$scenario_name",
					"stackable": true
				},
				{
					"freightClass": "70",
					"packageType": "CARTON",
					"totalWeight": 1000.0,
					"packageDimensions": {
						"length": 10.0,
						"width": 10.0,
						"height": 10.0
					},
					"totalPackages": 1,
					"totalPieces": 1,
					"description": "$scenario_name",
					"stackable": true
				}
			],
			"pickupWindow": {
				"date": "$(date -d 'tomorrow' +'%Y-%m-%d')",
				"startTime": "$(date -d 'tomorrow' +'%H:%M')",
				"endTime": "$(date -d 'tomorrow 6 hours' +'%H:%M')"
			},
			"deliveryWindow": {
				"date": "$(date -d '2 days' +'%Y-%m-%d')",
				"startTime": "$(date -d '2 days' +'%H:%M')",
				"endTime": "$(date -d '2 days 6 hours' +'%H:%M')"
			},
			"carrierCode": "$scac",
			"shipmentIdentifiers": [
				{
					"type": "CUSTOMER_REFERENCE",
					"value": "{$scac}_dispatch_test_{$scenario_number}_$(date +%s)"
				},
				{
					"type": "PURCHASE_ORDER",
					"value": "{$scac}_dispatch_test_{$scenario_number}_$(date +%s)"
				}
			],
			"accessorialServices": [],
			"pickupNote": "TOTAL 1 H/U",
			"emergencyContact": {},
			"capacityProviderQuoteNumber": "{$scac}_{$scenario_number}_$(date +%s)",
			"apiConfiguration": {
				"noteConfiguration": {
					"enableTruncation": true
				},
				"allowUnsupportedAccessorials": true,
				"pickupOnly": false
			}
		}
		EOF
		)
		curl_call=$(cat <<-EOF
			$curl_template '$request_data'
		EOF
		)
		
		if [ "$flg_generate_output" == "true" ]; then	
			echo "$curl_call" > "$(pwd)/$output_folder/${curl_call_scenario_file_prefix}_$scenario_number.txt"
		fi
		response=$(eval "$curl_call" | jq)
		dash_count=$(($total_status_output_length - ${#scenario_name} - ${#scenario_desc} - 1))
		dashes=$(printf '%*s' "$dash_count" | tr ' ' '-')
		if [ "$flg_use_quiet_mode" == "false" ]; then
			echo -e "$scenario_name $scenario_desc response:\n$(echo "$response" | jq)"
		else
			echo "$scenario_name $scenario_desc $dashes Status code: $(print_status_code "$response")"
		fi
	fi


	scenario_number="19"
	scenario_name="Scenario $scenario_number"
	scenario_desc="(description: null)"
	if [[ ("$flg_all" == "true" || " ${scenarios_to_run[@]} " =~ " $scenario_number ") && ! " ${scenarios_to_exclude[@]} " =~ " $scenario_number " ]]; then
	
		request_data=$(cat <<-EOF
		{
			"weightUnit": "LB",
			"lengthUnit": "IN",
			"paymentTermsOverride": "PREPAID",
			"directionOverride": "SHIPPER",
			"capacityProviderAccountGroup": {
				"code": "$account_group",
				"accounts": [
					{
						"code": "$scac"
					}
				]
			},
			"originLocation": {
				"address": {
					"country": "CA",
					"postalCode": "N0B1X0",
					"addressLines": [
						"1270 Geddes St"
					],
					"city": "Hawkesville $scenario_name",
					"state": "ON"
				},
				"contact": {
					"companyName": "A M I ATTACHMENTS INC",
					"contactName": "Darlene Ward",
					"phoneNumber": "5196993923",
					"email": "darlene.w@amiattachments.com"
				}
			},
			"destinationLocation": {
				"address": {
					"country": "CA",
					"postalCode": "T5M 2S1",
					"addressLines": [
						"16116  -111 Avenue Northwest"
					],
					"city": "Edmonton $scenario_name",
					"state": "AB"
				},
				"contact": {
					"companyName": "SMS Equipment Inc.",
					"contactName": "AARON RYAN",
					"phoneNumber": "7804512630"
				}
			},
			"requesterLocation": {
				"address": {
					"country": "CA",
					"postalCode": "N0B1X0",
					"addressLines": [
						"1270 Geddes St"
					],
					"city": "Hawkesville $scenario_name",
					"state": "ON"
				},
				"contact": {
					"companyName": "A M I ATTACHMENTS INC",
					"contactName": "Darlene Ward",
					"phoneNumber": "5196993923",
					"email": "darlene.w@amiattachments.com"
				}
			},
			"lineItems": [
				{
					"freightClass": "70",
					"packageType": "CARTON",
					"totalWeight": 1000.0,
					"packageDimensions": {
						"length": 10.0,
						"width": 10.0,
						"height": 10.0
					},
					"totalPackages": 1,
					"totalPieces": 1,
					"description": null,
					"stackable": false
				}
			],
			"pickupWindow": {
				"date": "$(date -d 'tomorrow' +'%Y-%m-%d')",
				"startTime": "$(date -d 'tomorrow' +'%H:%M')",
				"endTime": "$(date -d 'tomorrow 6 hours' +'%H:%M')"
			},
			"deliveryWindow": {
				"date": "$(date -d '2 days' +'%Y-%m-%d')",
				"startTime": "$(date -d '2 days' +'%H:%M')",
				"endTime": "$(date -d '2 days 6 hours' +'%H:%M')"
			},
			"carrierCode": "$scac",
			"shipmentIdentifiers": [
				{
					"type": "CUSTOMER_REFERENCE",
					"value": "{$scac}_dispatch_test_{$scenario_number}_$(date +%s)"
				},
				{
					"type": "PURCHASE_ORDER",
					"value": "{$scac}_dispatch_test_{$scenario_number}_$(date +%s)"
				}
			],
			"accessorialServices": [],
			"pickupNote": "TOTAL 1 H/U",
			"emergencyContact": {},
			"capacityProviderQuoteNumber": "{$scac}_{$scenario_number}_$(date +%s)",
			"apiConfiguration": {
				"noteConfiguration": {
					"enableTruncation": true
				},
				"allowUnsupportedAccessorials": true,
				"pickupOnly": false
			}
		}
		EOF
		)
		curl_call=$(cat <<-EOF
			$curl_template '$request_data'
		EOF
		)
		
		if [ "$flg_generate_output" == "true" ]; then	
			echo "$curl_call" > "$(pwd)/$output_folder/${curl_call_scenario_file_prefix}_$scenario_number.txt"
		fi
		response=$(eval "$curl_call" | jq)
		dash_count=$(($total_status_output_length - ${#scenario_name} - ${#scenario_desc} - 1))
		dashes=$(printf '%*s' "$dash_count" | tr ' ' '-')
		if [ "$flg_use_quiet_mode" == "false" ]; then
			echo -e "$scenario_name $scenario_desc response:\n$(echo "$response" | jq)"
		else
			echo "$scenario_name $scenario_desc $dashes Status code: $(print_status_code "$response")"
		fi
	fi




fi
# End of: run dispatch









# Start of: run tracking
if [ "$flg_run_tracking" == "true" ]; then

	# Set up logs
	logs_url="https://140271604703.observeinc.com/workspace/41124764/log-explorer?datasetId=41414971&time-preset=PAST_15_MINUTES&fv=41425674&s=21846-h6a5w00z"

	# Set up output folder
	if [ "$flg_generate_output" == "true" ]; then
		output_folder="curl_calls_${scac}_tracking_$(date +'%Y-%m-%d_%H-%M-%S')"
		if [ -d "$output_folder" ]; then
			rm -r "$output_folder"
			mkdir "$output_folder"
		else
			mkdir "$output_folder"
		fi
	fi
	
	
	curl_template=$(cat <<-EOF
	curl $curl_opts --location 'https://na12.api.qa-integration.p-44.com/api/v4/ltl/trackedshipments' \
		--header "Authorization: Bearer $token" \
		--header "Content-Type: application/json" \
		--data
	EOF
	)



	scenario_number="01"
	scenario_name="Scenario $scenario_number"
	scenario_desc="(PRO number)"
	if [[ ("$flg_all" == "true" || " ${scenarios_to_run[@]} " =~ " $scenario_number ") && ! " ${scenarios_to_exclude[@]} " =~ " $scenario_number " ]]; then
		# Scenario 01 (PRO number)
		if [ -z "$pro_num" ]; then
			dash_count=$(($total_status_output_length - ${#scenario_name} - ${#scenario_desc} - 1))
			dashes=$(printf '%*s' "$dash_count" | tr ' ' '-')
			echo "$scenario_name $scenario_desc $dashes $(print_error "PRO number not set!")"
		else
			request_data=$(cat <<-EOF
				{
				"capacityProviderAccountGroup": {
					"code": "$account_group",
					"accounts": [
						{
							"code": "$scac"
						}
					]
				},
				"shipmentIdentifiers": [
					{
						"type": "PRO",
						"value": "$pro_num"
					}
				],
				"shipmentStops": [
					{
						"stopType": "ORIGIN",
						"location": {
							"address": {
								"postalCode": "60555",
								"addressLines": [
									"29W600 Winchester Cir $scenario_name"
								],
								"city": "Warrenville $scenario_name",
								"state": "IL",
								"country": "US"
							},
							"contact": {
								"companyName": "Test Company $scenario_name"
							}
						},
						"appointmentWindow": {
							"startDateTime": "$(date -d 'yesterday' +'%Y-%m-%dT%H:%M:%S')",
							"endDateTime": "$(date -d 'yesterday' +'%Y-%m-%dT%H:%M:%S')"
						}
					},

					{
						"stopType": "DESTINATION",
						"location": {
							"address": {
								"postalCode": "08831",
								"addressLines": [
									"2 Hitching Post Place $scenario_name"
								],
								"city": "Monroe Township $scenario_name",
								"state": "NJ",
								"country": "US"
							},
							"contact": {
								"companyName": "Test Company $scenario_name"
							}
						},
						"appointmentWindow": {
							"startDateTime": "$(date -d '2 days' +'%Y-%m-%dT%H:%M:%S')",
							"endDateTime": "$(date -d '3 days' +'%Y-%m-%dT%H:%M:%S')"
						}
					}
				],
				"apiConfiguration": {
					"fallBackToDefaultAccountGroup": false
				},
				"shipmentAttributes": [
					{
						"name": "SyntheticLTLTest",
						"values": [
							"12345",
							"56789"
						]
					}
				]
			}
			EOF
			)

			curl_call=$(cat <<-EOF
				$curl_template '$request_data'
			EOF
			)

		if [ "$flg_generate_output" == "true" ]; then
			echo "$curl_call" > "$(pwd)/$output_folder/${curl_call_scenario_file_prefix}_$scenario_number.txt"
		fi
		response=$(eval "$curl_call" | jq)
		dash_count=$(($total_status_output_length - ${#scenario_name} - ${#scenario_desc} - 1))
		dashes=$(printf '%*s' "$dash_count" | tr ' ' '-')
		if [ "$flg_use_quiet_mode" == "false" ]; then
			echo -e "$scenario_name $scenario_desc response:\n$(echo "$response" | jq)"
		else
			echo "$scenario_name $scenario_desc $dashes Status code: $(print_status_code "$response")"
		fi
		fi
	fi


	scenario_number="02"
	scenario_name="Scenario $scenario_number"
	scenario_desc="(BOL number)"
	if [[ ("$flg_all" == "true" || " ${scenarios_to_run[@]} " =~ " $scenario_number ") && ! " ${scenarios_to_exclude[@]} " =~ " $scenario_number " ]]; then
		# Scenario 02 (BOL number)
		if [ -z "$bol_num" ]; then
			dash_count=$(($total_status_output_length - ${#scenario_name} - ${#scenario_desc} - 1))
			dashes=$(printf '%*s' "$dash_count" | tr ' ' '-')
			echo "$scenario_name $scenario_desc $dashes $(print_error "BOL number not set!")"
		else
			request_data=$(cat <<-EOF
				{
				"capacityProviderAccountGroup": {
					"code": "$account_group",
					"accounts": [
						{
							"code": "$scac"
						}
					]
				},
				"shipmentIdentifiers": [
					{
						"type": "BILL_OF_LADING",
						"value": "$bol_num"
					}
				],
				"shipmentStops": [
					{
						"stopType": "ORIGIN",
						"location": {
							"address": {
								"postalCode": "60555",
								"addressLines": [
									"29W600 Winchester Cir $scenario_name"
								],
								"city": "Warrenville $scenario_name",
								"state": "IL",
								"country": "US"
							},
							"contact": {
								"companyName": "Test Company $scenario_name"
							}
						},
						"appointmentWindow": {
							"startDateTime": "$(date -d 'yesterday' +'%Y-%m-%dT%H:%M:%S')",
							"endDateTime": "$(date -d 'yesterday' +'%Y-%m-%dT%H:%M:%S')"
						}
					},

					{
						"stopType": "DESTINATION",
						"location": {
							"address": {
								"postalCode": "08831",
								"addressLines": [
									"2 Hitching Post Place $scenario_name"
								],
								"city": "Monroe Township $scenario_name",
								"state": "NJ",
								"country": "US"
							},
							"contact": {
								"companyName": "Test Company $scenario_name"
							}
						},
						"appointmentWindow": {
							"startDateTime": "$(date -d '2 days' +'%Y-%m-%dT%H:%M:%S')",
							"endDateTime": "$(date -d '3 days' +'%Y-%m-%dT%H:%M:%S')"
						}
					}
				],
				"apiConfiguration": {
					"fallBackToDefaultAccountGroup": false
				},
				"shipmentAttributes": [
					{
						"name": "SyntheticLTLTest",
						"values": [
							"12345",
							"56789"
						]
					}
				]
			}
			EOF
			)

			curl_call=$(cat <<-EOF
				$curl_template '$request_data'
			EOF
			)

			if [ "$flg_generate_output" == "true" ]; then
				echo "$curl_call" > "$(pwd)/$output_folder/${curl_call_scenario_file_prefix}_$scenario_number.txt"
			fi
			response=$(eval "$curl_call" | jq)
			dash_count=$(($total_status_output_length - ${#scenario_name} - ${#scenario_desc} - 1))
			dashes=$(printf '%*s' "$dash_count" | tr ' ' '-')
			if [ "$flg_use_quiet_mode" == "false" ]; then
				echo -e "$scenario_name $scenario_desc response:\n$(echo "$response" | jq)"
			else
				echo "$scenario_name $scenario_desc $dashes Status code: $(print_status_code "$response")"
			fi	
		fi
	fi


	scenario_number="03"
	scenario_name="Scenario $scenario_number"
	scenario_desc="(PO number)"
	if [[ ("$flg_all" == "true" || " ${scenarios_to_run[@]} " =~ " $scenario_number ") && ! " ${scenarios_to_exclude[@]} " =~ " $scenario_number " ]]; then
		# Scenario 03 (PO number)
		if [ -z "$po_num" ]; then
			dash_count=$(($total_status_output_length - ${#scenario_name} - ${#scenario_desc} - 1))
			dashes=$(printf '%*s' "$dash_count" | tr ' ' '-')
			echo "$scenario_name $scenario_desc $dashes $(print_error "PO number not set!")"
		else
			request_data=$(cat <<-EOF
				{
				"capacityProviderAccountGroup": {
					"code": "$account_group",
					"accounts": [
						{
							"code": "$scac"
						}
					]
				},
				"shipmentIdentifiers": [
					{
						"type": "PURCHASE_ORDER",
						"value": "$po_num"
					}
				],
				"shipmentStops": [
					{
						"stopType": "ORIGIN",
						"location": {
							"address": {
								"postalCode": "60555",
								"addressLines": [
									"29W600 Winchester Cir $scenario_name"
								],
								"city": "Warrenville $scenario_name",
								"state": "IL",
								"country": "US"
							},
							"contact": {
								"companyName": "Test Company $scenario_name"
							}
						},
						"appointmentWindow": {
							"startDateTime": "$(date -d 'yesterday' +'%Y-%m-%dT%H:%M:%S')",
							"endDateTime": "$(date -d 'yesterday' +'%Y-%m-%dT%H:%M:%S')"
						}
					},

					{
						"stopType": "DESTINATION",
						"location": {
							"address": {
								"postalCode": "08831",
								"addressLines": [
									"2 Hitching Post Place $scenario_name"
								],
								"city": "Monroe Township $scenario_name",
								"state": "NJ",
								"country": "US"
							},
							"contact": {
								"companyName": "Test Company $scenario_name"
							}
						},
						"appointmentWindow": {
							"startDateTime": "$(date -d '2 days' +'%Y-%m-%dT%H:%M:%S')",
							"endDateTime": "$(date -d '3 days' +'%Y-%m-%dT%H:%M:%S')"
						}
					}
				],
				"apiConfiguration": {
					"fallBackToDefaultAccountGroup": false
				},
				"shipmentAttributes": [
					{
						"name": "SyntheticLTLTest",
						"values": [
							"12345",
							"56789"
						]
					}
				]
			}
			EOF
			)

			curl_call=$(cat <<-EOF
				$curl_template '$request_data'
			EOF
			)
		
		if [ "$flg_generate_output" == "true" ]; then
			echo "$curl_call" > "$(pwd)/$output_folder/${curl_call_scenario_file_prefix}_$scenario_number.txt"
		fi
		response=$(eval "$curl_call" | jq)
		dash_count=$(($total_status_output_length - ${#scenario_name} - ${#scenario_desc} - 1))
		dashes=$(printf '%*s' "$dash_count" | tr ' ' '-')
		if [ "$flg_use_quiet_mode" == "false" ]; then
			echo -e "$scenario_name $scenario_desc response:\n$(echo "$response" | jq)"
		else
			echo "$scenario_name $scenario_desc $dashes Status code: $(print_status_code "$response")"
		fi
		fi
	fi

	scenario_number="04"
	scenario_name="Scenario $scenario_number"
	scenario_desc="(date: valid)"
	if [[ ("$flg_all" == "true" || " ${scenarios_to_run[@]} " =~ " $scenario_number ") && ! " ${scenarios_to_exclude[@]} " =~ " $scenario_number " ]]; then
		# Scenario 04 (date: valid)
		request_data=$(cat <<-EOF
			{
			"capacityProviderAccountGroup": {
				"code": "$account_group",
				"accounts": [
					{
						"code": "$scac"
					}
				]
			},
			"shipmentIdentifiers": [
				{
					"type": "PRO",
					"value": "$pro_num"
				}
			],
			"shipmentStops": [
				{
					"stopType": "ORIGIN",
					"location": {
						"address": {
							"postalCode": "60555",
							"addressLines": [
								"29W600 Winchester Cir $scenario_name"
							],
							"city": "Warrenville $scenario_name",
							"state": "IL",
							"country": "US"
						},
						"contact": {
							"companyName": "Test Company $scenario_name"
						}
					},
					"appointmentWindow": {
						"startDateTime": "$(date -d 'yesterday' +'%Y-%m-%dT%H:%M:%S')",
						"endDateTime": "$(date -d 'yesterday' +'%Y-%m-%dT%H:%M:%S')"
					}
				},

				{
					"stopType": "DESTINATION",
					"location": {
						"address": {
							"postalCode": "08831",
							"addressLines": [
								"2 Hitching Post Place $scenario_name"
							],
							"city": "Monroe Township $scenario_name",
							"state": "NJ",
							"country": "US"
						},
						"contact": {
							"companyName": "Test Company $scenario_name"
						}
					},
					"appointmentWindow": {
						"startDateTime": "$(date -d '2 days' +'%Y-%m-%dT%H:%M:%S')",
						"endDateTime": "$(date -d '3 days' +'%Y-%m-%dT%H:%M:%S')"
					}
				}
			],
			"apiConfiguration": {
				"fallBackToDefaultAccountGroup": false
			},
			"shipmentAttributes": [
				{
					"name": "SyntheticLTLTest",
					"values": [
						"12345",
						"56789"
					]
				}
			]
		}
		EOF
		)

		curl_call=$(cat <<-EOF
			$curl_template '$request_data'
		EOF
		)

		if [ "$flg_generate_output" == "true" ]; then
			echo "$curl_call" > "$(pwd)/$output_folder/${curl_call_scenario_file_prefix}_$scenario_number.txt"
		fi
		response=$(eval "$curl_call" | jq)
		dash_count=$(($total_status_output_length - ${#scenario_name} - ${#scenario_desc} - 1))
		dashes=$(printf '%*s' "$dash_count" | tr ' ' '-')
		if [ "$flg_use_quiet_mode" == "false" ]; then
			echo -e "$scenario_name $scenario_desc response:\n$(echo "$response" | jq)"
		else
			echo "$scenario_name $scenario_desc $dashes Status code: $(print_status_code "$response")"
		fi
	fi


	scenario_number="05"
	scenario_name="Scenario $scenario_number"
	scenario_desc="(date: future)"
	if [[ ("$flg_all" == "true" || " ${scenarios_to_run[@]} " =~ " $scenario_number ") && ! " ${scenarios_to_exclude[@]} " =~ " $scenario_number " ]]; then
		# Scenario 05 (date: future)
		request_data=$(cat <<-EOF
			{
			"capacityProviderAccountGroup": {
				"code": "$account_group",
				"accounts": [
					{
						"code": "$scac"
					}
				]
			},
			"shipmentIdentifiers": [
				{
					"type": "PRO",
					"value": "$pro_num"
				}
			],
			"shipmentStops": [
				{
					"stopType": "ORIGIN",
					"location": {
						"address": {
							"postalCode": "60555",
							"addressLines": [
								"29W600 Winchester Cir $scenario_name"
							],
							"city": "Warrenville $scenario_name",
							"state": "IL",
							"country": "US"
						},
						"contact": {
							"companyName": "Test Company $scenario_name"
						}
					},
					"appointmentWindow": {
						"startDateTime": "$(date -d '1 hour' +'%Y-%m-%dT%H:%M:%S')",
						"endDateTime": "$(date -d '1 hour' +'%Y-%m-%dT%H:%M:%S')"
					}
				},

				{
					"stopType": "DESTINATION",
					"location": {
						"address": {
							"postalCode": "08831",
							"addressLines": [
								"2 Hitching Post Place $scenario_name"
							],
							"city": "Monroe Township $scenario_name",
							"state": "NJ",
							"country": "US"
						},
						"contact": {
							"companyName": "Test Company $scenario_name"
						}
					},
					"appointmentWindow": {
						"startDateTime": "$(date -d '2 days' +'%Y-%m-%dT%H:%M:%S')",
						"endDateTime": "$(date -d '3 days' +'%Y-%m-%dT%H:%M:%S')"
					}
				}
			],
			"apiConfiguration": {
				"fallBackToDefaultAccountGroup": false
			},
			"shipmentAttributes": [
				{
					"name": "SyntheticLTLTest",
					"values": [
						"12345",
						"56789"
					]
				}
			]
		}
		EOF
		)

		curl_call=$(cat <<-EOF
			$curl_template '$request_data'
		EOF
		)

		if [ "$flg_generate_output" == "true" ]; then
			echo "$curl_call" > "$(pwd)/$output_folder/${curl_call_scenario_file_prefix}_$scenario_number.txt"
		fi
		response=$(eval "$curl_call" | jq)
		dash_count=$(($total_status_output_length - ${#scenario_name} - ${#scenario_desc} - 1))
		dashes=$(printf '%*s' "$dash_count" | tr ' ' '-')
		if [ "$flg_use_quiet_mode" == "false" ]; then
			echo -e "$scenario_name $scenario_desc response:\n$(echo "$response" | jq)"
		else
			echo "$scenario_name $scenario_desc $dashes Status code: $(print_status_code "$response")"
		fi
	fi
	

	scenario_number="06"
	scenario_name="Scenario $scenario_number"
	scenario_desc="(date: past)"
	if [[ ("$flg_all" == "true" || " ${scenarios_to_run[@]} " =~ " $scenario_number ") && ! " ${scenarios_to_exclude[@]} " =~ " $scenario_number " ]]; then
		# Scenario 06 (date: past)
		request_data=$(cat <<-EOF
			{
			"capacityProviderAccountGroup": {
				"code": "$account_group",
				"accounts": [
					{
						"code": "$scac"
					}
				]
			},
			"shipmentIdentifiers": [
				{
					"type": "PRO",
					"value": "$pro_num"
				}
			],
			"shipmentStops": [
				{
					"stopType": "ORIGIN",
					"location": {
						"address": {
							"postalCode": "60555",
							"addressLines": [
								"29W600 Winchester Cir $scenario_name"
							],
							"city": "Warrenville $scenario_name",
							"state": "IL",
							"country": "US"
						},
						"contact": {
							"companyName": "Test Company $scenario_name"
						}
					},
					"appointmentWindow": {
						"startDateTime": "$(date -d 'yesterday' +'%Y-%m-%dT%H:%M:%S')",
						"endDateTime": "$(date -d 'yesterday' +'%Y-%m-%dT%H:%M:%S')"
					}
				},

				{
					"stopType": "DESTINATION",
					"location": {
						"address": {
							"postalCode": "08831",
							"addressLines": [
								"2 Hitching Post Place $scenario_name"
							],
							"city": "Monroe Township $scenario_name",
							"state": "NJ",
							"country": "US"
						},
						"contact": {
							"companyName": "Test Company $scenario_name"
						}
					},
					"appointmentWindow": {
						"startDateTime": "$(date -d '2 hours ago' +'%Y-%m-%dT%H:%M:%S')",
						"endDateTime": "$(date -d '1 hour ago' +'%Y-%m-%dT%H:%M:%S')"
					}
				}
			],
			"apiConfiguration": {
				"fallBackToDefaultAccountGroup": false
			},
			"shipmentAttributes": [
				{
					"name": "SyntheticLTLTest",
					"values": [
						"12345",
						"56789"
					]
				}
			]
		}
		EOF
		)

		curl_call=$(cat <<-EOF
			$curl_template '$request_data'
		EOF
		)

		if [ "$flg_generate_output" == "true" ]; then
			echo "$curl_call" > "$(pwd)/$output_folder/${curl_call_scenario_file_prefix}_$scenario_number.txt"
		fi
		response=$(eval "$curl_call" | jq)
		dash_count=$(($total_status_output_length - ${#scenario_name} - ${#scenario_desc} - 1))
		dashes=$(printf '%*s' "$dash_count" | tr ' ' '-')
		if [ "$flg_use_quiet_mode" == "false" ]; then
			echo -e "$scenario_name $scenario_desc response:\n$(echo "$response" | jq)"
		else
			echo "$scenario_name $scenario_desc $dashes Status code: $(print_status_code "$response")"
		fi
	fi



	scenario_number="07"
	scenario_name="Scenario $scenario_number"
	scenario_desc="(status codes)"
	if [[ ("$flg_all" == "true" || " ${scenarios_to_run[@]} " =~ " $scenario_number ") && ! " ${scenarios_to_exclude[@]} " =~ " $scenario_number " ]]; then
		# Scenario 07 (status codes)
		request_data=$(cat <<-EOF
			{
			"capacityProviderAccountGroup": {
				"code": "$account_group",
				"accounts": [
					{
						"code": "$scac"
					}
				]
			},
			"shipmentIdentifiers": [
				{
					"type": "PRO",
					"value": "$pro_num"
				}
			],
			"shipmentStops": [
				{
					"stopType": "ORIGIN",
					"location": {
						"address": {
							"postalCode": "60555",
							"addressLines": [
								"29W600 Winchester Cir $scenario_name"
							],
							"city": "Warrenville $scenario_name",
							"state": "IL",
							"country": "US"
						},
						"contact": {
							"companyName": "Test Company $scenario_name"
						}
					},
					"appointmentWindow": {
						"startDateTime": "$(date -d 'yesterday' +'%Y-%m-%dT%H:%M:%S')",
						"endDateTime": "$(date -d 'yesterday' +'%Y-%m-%dT%H:%M:%S')"
					}
				},

				{
					"stopType": "DESTINATION",
					"location": {
						"address": {
							"postalCode": "08831",
							"addressLines": [
								"2 Hitching Post Place $scenario_name"
							],
							"city": "Monroe Township $scenario_name",
							"state": "NJ",
							"country": "US"
						},
						"contact": {
							"companyName": "Test Company $scenario_name"
						}
					},
					"appointmentWindow": {
						"startDateTime": "$(date -d '2 days' +'%Y-%m-%dT%H:%M:%S')",
						"endDateTime": "$(date -d '3 days' +'%Y-%m-%dT%H:%M:%S')"
					}
				}
			],
			"apiConfiguration": {
				"fallBackToDefaultAccountGroup": false
			},
			"shipmentAttributes": [
				{
					"name": "SyntheticLTLTest",
					"values": [
						"12345",
						"56789"
					]
				}
			]
		}
		EOF
		)

		curl_call=$(cat <<-EOF
			$curl_template '$request_data'
		EOF
		)

		if [ "$flg_generate_output" == "true" ]; then
			echo "$curl_call" > "$(pwd)/$output_folder/${curl_call_scenario_file_prefix}_$scenario_number.txt"
		fi
		response=$(eval "$curl_call" | jq)
		dash_count=$(($total_status_output_length - ${#scenario_name} - ${#scenario_desc} - 1))
		dashes=$(printf '%*s' "$dash_count" | tr ' ' '-')
		if [ "$flg_use_quiet_mode" == "false" ]; then
			echo -e "$scenario_name $scenario_desc response:\n$(echo "$response" | jq)"
		else
			echo "$scenario_name $scenario_desc $dashes Status code: $(print_status_code "$response")"
		fi
	fi



	scenario_number="08"
	scenario_name="Scenario $scenario_number"
	scenario_desc="(event status descriptions)"
	if [[ ("$flg_all" == "true" || " ${scenarios_to_run[@]} " =~ " $scenario_number ") && ! " ${scenarios_to_exclude[@]} " =~ " $scenario_number " ]]; then
		# Scenario 08 (event status descriptions)
		request_data=$(cat <<-EOF
			{
			"capacityProviderAccountGroup": {
				"code": "$account_group",
				"accounts": [
					{
						"code": "$scac"
					}
				]
			},
			"shipmentIdentifiers": [
				{
					"type": "PRO",
					"value": "$pro_num"
				}
			],
			"shipmentStops": [
				{
					"stopType": "ORIGIN",
					"location": {
						"address": {
							"postalCode": "60555",
							"addressLines": [
								"29W600 Winchester Cir $scenario_name"
							],
							"city": "Warrenville $scenario_name",
							"state": "IL",
							"country": "US"
						},
						"contact": {
							"companyName": "Test Company $scenario_name"
						}
					},
					"appointmentWindow": {
						"startDateTime": "$(date -d 'yesterday' +'%Y-%m-%dT%H:%M:%S')",
						"endDateTime": "$(date -d 'yesterday' +'%Y-%m-%dT%H:%M:%S')"
					}
				},

				{
					"stopType": "DESTINATION",
					"location": {
						"address": {
							"postalCode": "08831",
							"addressLines": [
								"2 Hitching Post Place $scenario_name"
							],
							"city": "Monroe Township $scenario_name",
							"state": "NJ",
							"country": "US"
						},
						"contact": {
							"companyName": "Test Company $scenario_name"
						}
					},
					"appointmentWindow": {
						"startDateTime": "$(date -d '2 days' +'%Y-%m-%dT%H:%M:%S')",
						"endDateTime": "$(date -d '3 days' +'%Y-%m-%dT%H:%M:%S')"
					}
				}
			],
			"apiConfiguration": {
				"fallBackToDefaultAccountGroup": false
			},
			"shipmentAttributes": [
				{
					"name": "SyntheticLTLTest",
					"values": [
						"12345",
						"56789"
					]
				}
			]
		}
		EOF
		)

		curl_call=$(cat <<-EOF
			$curl_template '$request_data'
		EOF
		)

		if [ "$flg_generate_output" == "true" ]; then
			echo "$curl_call" > "$(pwd)/$output_folder/${curl_call_scenario_file_prefix}_$scenario_number.txt"
		fi
		response=$(eval "$curl_call" | jq)
		dash_count=$(($total_status_output_length - ${#scenario_name} - ${#scenario_desc} - 1))
		dashes=$(printf '%*s' "$dash_count" | tr ' ' '-')
		if [ "$flg_use_quiet_mode" == "false" ]; then
			echo -e "$scenario_name $scenario_desc response:\n$(echo "$response" | jq)"
		else
			echo "$scenario_name $scenario_desc $dashes Status code: $(print_status_code "$response")"
		fi
	fi



	scenario_number="09"
	scenario_name="Scenario $scenario_number"
	scenario_desc="(status discrepancies)"
	if [[ ("$flg_all" == "true" || " ${scenarios_to_run[@]} " =~ " $scenario_number ") && ! " ${scenarios_to_exclude[@]} " =~ " $scenario_number " ]]; then
		# Scenario 09 (status discrepancies)
		request_data=$(cat <<-EOF
			{
			"capacityProviderAccountGroup": {
				"code": "$account_group",
				"accounts": [
					{
						"code": "$scac"
					}
				]
			},
			"shipmentIdentifiers": [
				{
					"type": "PRO",
					"value": "$pro_num"
				}
			],
			"shipmentStops": [
				{
					"stopType": "ORIGIN",
					"location": {
						"address": {
							"postalCode": "60555",
							"addressLines": [
								"29W600 Winchester Cir $scenario_name"
							],
							"city": "Warrenville $scenario_name",
							"state": "IL",
							"country": "US"
						},
						"contact": {
							"companyName": "Test Company $scenario_name"
						}
					},
					"appointmentWindow": {
						"startDateTime": "$(date -d 'yesterday' +'%Y-%m-%dT%H:%M:%S')",
						"endDateTime": "$(date -d 'yesterday' +'%Y-%m-%dT%H:%M:%S')"
					}
				},

				{
					"stopType": "DESTINATION",
					"location": {
						"address": {
							"postalCode": "08831",
							"addressLines": [
								"2 Hitching Post Place $scenario_name"
							],
							"city": "Monroe Township $scenario_name",
							"state": "NJ",
							"country": "US"
						},
						"contact": {
							"companyName": "Test Company $scenario_name"
						}
					},
					"appointmentWindow": {
						"startDateTime": "$(date -d '2 days' +'%Y-%m-%dT%H:%M:%S')",
						"endDateTime": "$(date -d '3 days' +'%Y-%m-%dT%H:%M:%S')"
					}
				}
			],
			"apiConfiguration": {
				"fallBackToDefaultAccountGroup": false
			},
			"shipmentAttributes": [
				{
					"name": "SyntheticLTLTest",
					"values": [
						"12345",
						"56789"
					]
				}
			]
		}
		EOF
		)

		curl_call=$(cat <<-EOF
			$curl_template '$request_data'
		EOF
		)

		if [ "$flg_generate_output" == "true" ]; then
			echo "$curl_call" > "$(pwd)/$output_folder/${curl_call_scenario_file_prefix}_$scenario_number.txt"
		fi
		response=$(eval "$curl_call" | jq)
		dash_count=$(($total_status_output_length - ${#scenario_name} - ${#scenario_desc} - 1))
		dashes=$(printf '%*s' "$dash_count" | tr ' ' '-')
		if [ "$flg_use_quiet_mode" == "false" ]; then
			echo -e "$scenario_name $scenario_desc response:\n$(echo "$response" | jq)"
		else
			echo "$scenario_name $scenario_desc $dashes Status code: $(print_status_code "$response")"
		fi
	fi



	scenario_number="10"
	scenario_name="Scenario $scenario_number"
	scenario_desc="(tracking accuracy)"
	if [[ ("$flg_all" == "true" || " ${scenarios_to_run[@]} " =~ " $scenario_number ") && ! " ${scenarios_to_exclude[@]} " =~ " $scenario_number " ]]; then
		# Scenario 10 (tracking accuracy)
		request_data=$(cat <<-EOF
			{
			"capacityProviderAccountGroup": {
				"code": "$account_group",
				"accounts": [
					{
						"code": "$scac"
					}
				]
			},
			"shipmentIdentifiers": [
				{
					"type": "PRO",
					"value": "$pro_num"
				}
			],
			"shipmentStops": [
				{
					"stopType": "ORIGIN",
					"location": {
						"address": {
							"postalCode": "60555",
							"addressLines": [
								"29W600 Winchester Cir $scenario_name"
							],
							"city": "Warrenville $scenario_name",
							"state": "IL",
							"country": "US"
						},
						"contact": {
							"companyName": "Test Company $scenario_name"
						}
					},
					"appointmentWindow": {
						"startDateTime": "$(date -d 'yesterday' +'%Y-%m-%dT%H:%M:%S')",
						"endDateTime": "$(date -d 'yesterday' +'%Y-%m-%dT%H:%M:%S')"
					}
				},

				{
					"stopType": "DESTINATION",
					"location": {
						"address": {
							"postalCode": "08831",
							"addressLines": [
								"2 Hitching Post Place $scenario_name"
							],
							"city": "Monroe Township $scenario_name",
							"state": "NJ",
							"country": "US"
						},
						"contact": {
							"companyName": "Test Company $scenario_name"
						}
					},
					"appointmentWindow": {
						"startDateTime": "$(date -d '2 days' +'%Y-%m-%dT%H:%M:%S')",
						"endDateTime": "$(date -d '3 days' +'%Y-%m-%dT%H:%M:%S')"
					}
				}
			],
			"apiConfiguration": {
				"fallBackToDefaultAccountGroup": false
			},
			"shipmentAttributes": [
				{
					"name": "SyntheticLTLTest",
					"values": [
						"12345",
						"56789"
					]
				}
			]
		}
		EOF
		)

		curl_call=$(cat <<-EOF
			$curl_template '$request_data'
		EOF
		)

		if [ "$flg_generate_output" == "true" ]; then
			echo "$curl_call" > "$(pwd)/$output_folder/${curl_call_scenario_file_prefix}_$scenario_number.txt"
		fi
		response=$(eval "$curl_call" | jq)
		dash_count=$(($total_status_output_length - ${#scenario_name} - ${#scenario_desc} - 1))
		dashes=$(printf '%*s' "$dash_count" | tr ' ' '-')
		if [ "$flg_use_quiet_mode" == "false" ]; then
			echo -e "$scenario_name $scenario_desc response:\n$(echo "$response" | jq)"
		else
			echo "$scenario_name $scenario_desc $dashes Status code: $(print_status_code "$response")"
		fi
	fi

	# Create helper doc
	if [ "$flg_generate_output" == "true" ]; then
		grep -R -E 'type|value' "$output_folder/${curl_call_scenario_file_prefix}"* >> "$output_folder/$helper_doc_file_name"
		grep -R -E 'startDate|endDate' "$output_folder/${curl_call_scenario_file_prefix}"* >> "$output_folder/$helper_doc_file_name"
	fi
	

	echo "Logs: $logs_url"
fi
# End of: run tracking








