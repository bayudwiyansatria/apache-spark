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

    # System Operation Information
    if type lsb_release >/dev/null 2>&1 ; then
    os=$(lsb_release -i -s);
    elif [ -e /etc/os-release ] ; then
    os=$(awk -F= '$1 == "ID" {print $2}' /etc/os-release);
    elif [ -e /etc/*-os-release ] ; then
    os=$(awk -F= '$1 == "ID" {print $3}' /etc/*-os-release);
    fi

    os=$(printf '%s\n' "$os" | LC_ALL=C tr '[:upper:]' '[:lower:]');

    read -p "Update Distro (y/n) [ENTER] (y)(Recommended): " update;
    if [ $update == "y" ] ; then
        if [ $os == "ubuntu" ] ; then
            apt-get -y update && apt-get -y upgrade;
        else 
            yum -y update && yum -y upgrade;
        fi
    fi

    if [ $os == "ubuntu" ] ; then
        apt-get -y install git && apt-get -y install wget;
    else 
        yum -y install git && yum -y install wget;
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
    else
        distribution="stable";
        version="2.4.3";
        packages="spark-$version";
    fi

    argv="$1";
    echo $argv;
    if [ "$argv" ] ; then
        distribution="spark-$argv";
        packages=$distribution;
    else
        read -p "Enter spark distribution version, (NULL FOR STABLE) [ENTER] : "  version;
        if [ -z "$version" ] ; then 
            echo "spark version is not specified! Installing spark with lastest stable version";
            distribution="stable";
            version="2.4.0";
            packages="spark-$version";
        else
            distribution="spark-$version";
            packages=$distribution;
        fi
    fi

    echo "################################################";
    echo "##         Collect Spark Distribution         ##";
    echo "################################################";
    echo "";

    # Packages Available
    url=https://www-eu.apache.org/dist/spark/$distribution/$packages.tar.gz;
    echo "Checking availablility spark $version";
    if curl --output /dev/null --silent --head --fail "$url"; then
        echo "spark version is available: $url";
    else
        echo "spark version isn't available: $url";
        exit 1;
    fi

    echo "spark version $version install is in progress, Please keep your computer power on";

    wget https://www-eu.apache.org/dist/spark/$distribution/$packages.tar.gz -O /tmp/$packages.tar.gz;

    echo "";
    echo "################################################";
    echo "##             Spark Installation            ##";
    echo "################################################";
    echo "";

    echo "Installing Spark Version  $distribution";
    echo "";

    # Extraction Packages
    tar -xvf /tmp/$packages.tar.gz;
    mkdir -p /usr/local/spark;
    mv /tmp/$packages /usr/local/spark;

    # User Generator
    read -p "Enter username : " username;
    read -s -p "Enter password : " password;
    egrep "^$username" /etc/passwd >/dev/null;
    if [ $? -eq 0 ]; then
        echo "$username exists!"
    else
        pass=$(perl -e 'print crypt($ARGV[0], "password")' $password)
        useradd -m -p $pass $username
        [ $? -eq 0 ] && echo "User has been added to system!" || echo "Failed to add a user!"
    fi

    usermod -aG $username $password;
    chown $username:root -R /usr/local/spark;
    chmod g+rwx -R /usr/local/spark;

    echo "";
    echo "################################################";
    echo "##             Spark Configuration            ##";
    echo "################################################";
    echo "";

    read -p "Using default configuration (y/n) [ENTER] (y): " conf;
    if $conf == "y" ; then
        for configuration in "${files[@]}" ; do 
            wget https://raw.githubusercontent.com/bayudwiyansatria/Apache-Spark-Environment/master/$packages/conf/$configuration -O /tmp/$configuration;
            rm $SPARK_HOME/conf/$configuration;
            cp /tmp/$configuration $SPARK_HOME/conf;
        done
    fi

    echo "";
    echo "################################################";
    echo "##             Java Virtual Machine           ##";
    echo "################################################";
    echo "";

    echo "Checking Java virtual machine is running on your machine";

    java=$(echo "$JAVA_HOME");
    if [ -z "$java" ] ; then
        if [ $os == "ubuntu" ] ; then
            apt-get -y install git && apt-get -y install wget;
        else 
            yum install java-1.8.0-openjdk;
            java=$(dirname $(readlink -f $(which java))|sed 's^/bin^^');
            python=$(dirname $(readlink -f $(which java)));
            env=$(echo "$PATH");
            echo -e 'export LOCAL_PATH="'$env'"' >> /home/$username/.bash_profile;
            echo -e 'export JAVA_HOME="'$java'"' >> /home/$username/.bash_profile;
            echo -e '# Apache Spark Environment' >> /home/$username/.bash_profile;
            echo -e 'export SPARK_HOME=="'$SPARK_HOME'"' >> /home/$username/.bash_profile;
            echo -e 'export SPARK_CONF_DIR==${SPARK_HOME}/conf' >> /home/$username/.bash_profile;
            echo -e 'export SPARK_HISTORY_OPTS=""' >> /home/$username/.bash_profile;
            echo -e 'export PYSPARK_PYTHON="'$python'"' >> /home/$username/.bash_profile;
            echo -e 'export SPARK=${SPARK_HOME}/bin:${SPARK_HOME}/sbin' >> /home/$username/.bash_profile;

            hadoop=$(echo "$HADOOP_HOME");
            if [ -z "$HADOOP_HOME"] ; then
                echo -e 'export PATH=${LOCAL_PATH}:${SPARK_HOME}' >> /home/$username/.bash_profile;
            else
                echo -e 'export PATH=${LOCAL_PATH}:${HADOOP}:${SPARK_HOME}' >> /home/$username/.bash_profile;
            fi
        fi
    else
        java=$(dirname $(readlink -f $(which java))|sed 's^/bin^^');
        python=$(dirname $(readlink -f $(which java)));
        env=$(echo "$PATH");
        echo -e 'export LOCAL_PATH="'$env'"' >> /home/$username/.bash_profile;
        echo -e 'export JAVA_HOME="'$java'"' >> /home/$username/.bash_profile;
        echo -e '# Apache Spark Environment' >> /home/$username/.bash_profile;
        echo -e 'export SPARK_HOME=="'$SPARK_HOME'"' >> /home/$username/.bash_profile;
        echo -e 'export SPARK_CONF_DIR==${SPARK_HOME}/conf' >> /home/$username/.bash_profile;
        echo -e 'export SPARK_HISTORY_OPTS=""' >> /home/$username/.bash_profile;
        echo -e 'export PYSPARK_PYTHON="'$python'"' >> /home/$username/.bash_profile;
        echo -e 'export SPARK=${SPARK_HOME}/bin:${SPARK_HOME}/sbin' >> /home/$username/.bash_profile;

        hadoop=$(echo "$HADOOP_HOME");
        if [ -z "$HADOOP_HOME"] ; then
            echo -e 'export PATH=${LOCAL_PATH}:${SPARK_HOME}' >> /home/$username/.bash_profile;
        else
            echo -e 'export PATH=${LOCAL_PATH}:${HADOOP}:${SPARK_HOME}' >> /home/$username/.bash_profile;
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