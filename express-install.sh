#!/bin/bash
echo "";

echo "################################################";
echo "##  Welcom To Bayu Dwiyan Satria Installation ##";
echo "################################################";

echo "";

echo "Use of code or any part of it is strictly prohibited.";
echo "File protected by copyright law and provided under license.";
echo "To Use any part of this code you need to get a writen approval from the code owner: bayudwiyansatria@gmail.com.";

echo "";

# User Access
if [ $(id -u) -eq 0 ]; then

    echo "################################################";
    echo "##        Checking System Compability         ##";
    echo "################################################";

    echo "";
    echo "Please wait! Checking System Compability";
    echo "";

    # Operation System Information
    if type lsb_release >/dev/null 2>&1 ; then
        os=$(lsb_release -i -s);
    elif [ -e /etc/os-release ] ; then
        os=$(awk -F= '$1 == "ID" {print $2}' /etc/os-release);
    elif [ -e /etc/os-release ] ; then
        os=$(awk -F= '$1 == "ID" {print $3}' /etc/os-release);
    else
        exit 1;
    fi

    os=$(printf '%s\n' "$os" | LC_ALL=C tr '[:upper:]' '[:lower:]' | sed 's/"//g');

    # Update OS Current Distribution
    if [ "$os" == "ubuntu" ] || [ "$os" == "debian" ] ; then
        apt-get -y update && apt-get -y upgrade;
    elif [ "$os" == "centos" ] || [ "$os" == "rhel" ] || [ "$os" == "fedora" ] ; then
        yum -y update && yum -y upgrade;
    else
        exit 1;
    fi

    # Required Packages
    if [ "$os" == "ubuntu" ] || [ "$os" == "debian" ] ; then
        apt-get -y install git && apt-get -y install wget;
    elif [ "$os" == "centos" ] || [ "$os" == "rhel" ] || [ "$os" == "fedora" ]; then
        yum -y install git && yum -y install wget;
    else
        exit 1;
    fi

    echo "################################################";
    echo "##          Check Spark Environment           ##";
    echo "################################################";
    echo "";

    echo "We checking spark is running on your system";

    SPARK_HOME="/usr/local/spark";
    
    if [ -e "$SPARK_HOME" ]; then
        echo "";
        echo "Spark is already installed on your machines.";
        echo "";
        exit 1;
    else
        echo "Preparing install spark";
        echo "";
    fi

    argv="$1";
    echo $argv;
    if [ "$argv" ] ; then
        distribution="spark-$argv";
        packages=$distribution;
        read -p "Using hadoop binary? (y/N) [ENTER] (y) : "  hadoop;
        hadoop=$(printf '%s\n' "$hadoop" | LC_ALL=C tr '[:upper:]' '[:lower:]' | sed 's/"//g');
        if [ "$hadoop" == "y" ]; then
            packages="$packages-bin-hadoop2.7"
        fi
    else
        distribution="stable";
        version="2.4.3";
        packages="spark-$version";
        read -p "Using hadoop binary? (y/N) [ENTER] (y) : "  hadoop;
        hadoop=$(printf '%s\n' "$hadoop" | LC_ALL=C tr '[:upper:]' '[:lower:]' | sed 's/"//g');
        if [ "$hadoop" == "y" ]; then
            packages="$packages-bin-hadoop2.7"
        fi
    fi

    echo "################################################";
    echo "##         Collect Spark Distribution         ##";
    echo "################################################";
    echo "";

    # Packages Available
    mirror=https://www-eu.apache.org/dist/spark;
    url=$mirror/$distribution/$packages.tgz;
    echo "Checking availablility spark $version";
    if curl --output /dev/null --silent --head --fail "$url"; then
        echo "Spark version is available: $url";
    else
        echo "Spark version isn't available: $url";
        exit 1;
    fi

    echo "";
    echo "Spark version $version install is in progress, Please keep your computer power on";

    wget $mirror/$distribution/$packages.tgz -O /tmp/$packages.tgz;

    echo "";
    echo "################################################";
    echo "##             Spark Installation            ##";
    echo "################################################";
    echo "";

    echo "Installing Spark Version $distribution";
    echo "";

    # Extraction Packages
    tar -xvf /tmp/$packages.tgz;
    mv $packages $SPARK_HOME;

    # User Generator
    username="spark";
    password="spark";
    egrep "^$username" /etc/passwd >/dev/null;
    if [ $? -eq 0 ]; then
        echo "$username exists!"
    else
        pass=$(perl -e 'print crypt($ARGV[0], "password")' $password)
        useradd -m -p $pass $username
        [ $? -eq 0 ] && echo "User has been added to system!" || echo "Failed to add a user!"
        usermod -aG $username $password;
        echo "User $username created successfully";
        echo "";
    fi

    chown $username:root -R $SPARK_HOME;
    chmod g+rwx -R $SPARK_HOME;


    echo "";
    echo "################################################";
    echo "##             Spark Configuration            ##";
    echo "################################################";
    echo "";

    echo "Generate configuration file";

    # Configuration Variable
    files=(slaves spark-defaults.conf spark-env.sh);
    for configuration in "${files[@]}" ; do 
        wget https://raw.githubusercontent.com/bayudwiyansatria/Apache-Spark-Environment/master/$packages/conf/$configuration -O /tmp/$configuration;
        rm $SPARK_HOME/conf/$configuration;
        cp /tmp/$configuration $SPARK_HOME/conf;
    done

    echo "";
    echo "################################################";
    echo "##             Java Virtual Machine           ##";
    echo "################################################";
    echo "";

    echo "Checking Java virtual machine is running on your machine";

    profile="/etc/profile.d/bayudwiyansatria.sh";
    env=$(echo "$PATH");
    if [ -e "$profile" ] ; then
        echo "Environment already setup";
    else
        touch $profile;
        echo -e 'export LOCAL_PATH="'$env'"' >> $profile;
    fi

    java=$(echo "$JAVA_HOME");
    if [ -z "$java" ] ; then
        if [ $os == "ubuntu" ] ; then
            apt-get -y install git && apt-get -y install wget;
        else 
            yum install java-1.8.0-openjdk;
            java=$(dirname $(readlink -f $(which java))|sed 's^/bin^^');
            python=$(dirname $(readlink -f $(which java)));
            echo -e 'export JAVA_HOME="'$java'"' >> $profile;
            echo -e '# Apache Spark Environment' >> $profile;
            echo -e 'export SPARK_HOME="'$SPARK_HOME'"' >> $profile;
            echo -e 'export SPARK_CONF_DIR=${SPARK_HOME}/conf' >> $profile;
            echo -e 'export SPARK_HISTORY_OPTS=""' >> $profile;
            echo -e 'export PYSPARK_PYTHON="'$python'"' >> $profile;
            echo -e 'export SPARK=${SPARK_HOME}/bin:${SPARK_HOME}/sbin' >> $profile;

            hadoop=$(echo "$HADOOP");
            if [ -z "$HADOOP"] ; then
                echo -e 'export PATH=${LOCAL_PATH}:${SPARK}' >> $profile;
            else
                echo -e 'export PATH=${LOCAL_PATH}:${HADOOP}:${SPARK}' >> $profile;
            fi
        fi
    else
        java=$(dirname $(readlink -f $(which java))|sed 's^/bin^^');
        python=$(dirname $(readlink -f $(which java)));
        echo -e 'export JAVA_HOME="'$java'"' >> $profile;
        echo -e '# Apache Spark Environment' >> $profile;
        echo -e 'export SPARK_HOME="'$SPARK_HOME'"' >> $profile;
        echo -e 'export SPARK_CONF_DIR=${SPARK_HOME}/conf' >> $profile;
        echo -e 'export SPARK_HISTORY_OPTS=""' >> $profile;
        echo -e 'export PYSPARK_PYTHON="'$python'"' >> $profile;
        echo -e 'export SPARK=${SPARK_HOME}/bin:${SPARK_HOME}/sbin' >> $profile;

        hadoop=$(echo "$HADOOP");
        if [ -z "$HADOOP"] ; then
            echo -e 'export PATH=${LOCAL_PATH}:${SPARK}' >> $profile;
        else
            echo -e 'export PATH=${LOCAL_PATH}:${HADOOP}:${SPARK}' >> $profile;
        fi
    fi

    echo "Successfully Checking";

    echo "";
    echo "############################################";
    echo "## Thank You For Using Bayu Dwiyan Satria ##";
    echo "############################################";
    echo "";
    
    echo "Installing Spark $version Successfully";
    echo "Installed Directory $SPARK_HOME";
    echo "";

    echo "User $username";
    echo "Pass $password";
    echo "";

    echo "Author    : Bayu Dwiyan Satria";
    echo "Email     : bayudwiyansatria@gmail.com";
    echo "Feel free to contact us";
    echo "";

    read -p "Do you want to reboot? (y/N) [ENTER] [y] : "  reboot;
    if [ -n "$reboot" ] ; then
        if [ "$reboot" == "y" ]; then
            reboot;
        else
            echo "We highly recomended to reboot your system";
        fi
    else
        reboot;
    fi

else
    echo "Only root may can install to the system";
    exit 1;
fi