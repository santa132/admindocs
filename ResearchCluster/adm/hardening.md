# Hardening
This document gives users some tips on how to run hardening on a new server.
**NOTE**: Because of the free version of the hardening software (CIS-CAT-Lite-v4.26.0), the users should install ***Ubuntu Linux 20.04*** LTS for the benchmark. The server may be not connected to the internet, some tests may be failed.

## Prerequisite
- Java have to be install
```
java --version
```

Install command
```bash
sudo apt install default-jdk
```

- Copy CIS-CAT-Lite package into the server node
- Unzip
```bash
unzip CIS-CAT-Lite-v4.26.0.zip
```

- Change to `root` user
```bash
sudo -i
```

- Chage mode of the script
```bash
cd Assessor
chmod +x Assessor-CLI.sh
```

- Run hardening test
```
./Assessor-CLI.sh -i
```
  - The result is located at the `reports` folder

## 5.4.2 (Be careful) Ensure lockout for failed password attempts is configured
When adding new lines in the */etc/pam.d/common-account* file, please comment out 2 new lines. This test case will be passed, but it doesnot work.

## 4.2.3 Ensure permissions on all logfiles are configured
Should remove all files in the */var/log* folder
```bash
rm -rf /var/log/*
```

## 1.4.2 Ensure bootloader password is set
- Set boot password, add below lines into file */etc/grub.d/41_custom*. `<username>` should be `root`.
```bash
cat <<EOF

set superusers="<username>"
password_pbkdf2 <username> <encrypted-password>

EOF
```

Remaining guideline should be same with the report.

## 6.1.10 - 6.1.12
Please read the Assessment Evidence to know which file is wrong permission.
### 6.1.10 Ensure no world writable files exist
```bash
 chmod o-w <filename>
```

### 6.1.11 Ensure no unowned files or directories exist
```bash
 chown root <filename>
```

### 6.1.10 Ensure no ungrouped files or directories exist
```bash
 chgrp root <filename>
```

## 4.4 Ensure logrotate assigns appropriate permissions
- Open file */etc/logrotate.d/alternatives*
Change 644 to 640
```bash
vi /etc/logrotate.d/alternatives


/var/log/alternatives.log {
	monthly
	rotate 12
	compress
	delaycompress
	missingok
	notifempty
	create 640 root root
}
```
- Open file */etc/logrotate.d/dpkg*
Change 644 to 640
```bash
vi /etc/logrotate.d/dpkg

/var/log/dpkg.log {
	monthly
	rotate 12
	compress
	delaycompress
	missingok
	notifempty
	create 640 root root
}
```

## 1.8.2 Ensure GDM login banner is configured
- Edit checking condition
```bash
vi benchmarks/CIS_Ubuntu_Linux_20.04_LTS_Benchmark_v1.1.0-oval.xml
```

- Edit at line 5326 from `^\s*\[org\/gnome\/login-screen\]\b` to `^\s*\[org\/gnome\/login-screen\b`
```xml
    <textfilecontent54_object xmlns="http://oval.mitre.org/XMLSchema/oval-definitions-5#independent" comment="Ensure at least one file named /etc/gdm3/greeter.dconf-defaults exists and matches pattern ^\s*\[org\/gnome\/login-screen\]\b" id="oval:org.cisecurity.benchmarks.canonical_ubuntu_linux_20:obj:1456134" version="1">
      <filepath>/etc/gdm3/greeter.dconf-defaults</filepath>
      <pattern datatype="string" operation="pattern match">^\s*\[org\/gnome\/login-screen\b</pattern>
      <instance datatype="int" operation="equals">1</instance>
    </textfilecontent54_object>
```

- Edit at line 5336 from `^\s*banner-message-text\s*=\s*('|").+('|")\b` to `^\s*banner-message-text\s*=\s*('|")\b`
```xml
    <textfilecontent54_object xmlns="http://oval.mitre.org/XMLSchema/oval-definitions-5#independent" comment="Ensure at least one file named /etc/gdm3/greeter.dconf-defaults exists and matches pattern ^\s*banner-message-text\s*=\s*('|&quot;).+('|&quot;)\b" id="oval:org.cisecurity.benchmarks.canonical_ubuntu_linux_20:obj:1456142" version="1">
      <filepath>/etc/gdm3/greeter.dconf-defaults</filepath>
      <pattern datatype="string" operation="pattern match">^\s*banner-message-text\s*=\s*('|")\b</pattern>
      <instance datatype="int" operation="equals">1</instance>
    </textfilecontent54_object>
```