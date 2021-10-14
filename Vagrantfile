$script_mysql = <<-SCRIPT
  apt-get update && \
  apt-get install -y mysql-server-5.7 && \
  mysql < /vagrant/mysql/script/user.sql && \
  mysql < /vagrant/mysql/script/schema.sql && \
  mysql < /vagrant/mysql/script/data.sql && \
  cat /vagrant/mysql/mysqld.cnf > /etc/mysql/mysql.conf.d/mysqld.cnf && \
  service mysql restart
SCRIPT

Vagrant.configure("2") do |config|
  #configurando a VM

    config.vm.define:teste do |teste_config|

      teste_config.vm.box = "fnando/dev-bionic64"
      #teste_config.vm.network "fowarded_port", guest: 80 , host: 8080
      teste_config.ssh.insert_key = false 
      teste_config.vm.provider:virtualbox do |v|
        v.memory = 1024
        v.cpus = 1
      
      end   
    end

    config.vm.define:mysqlserver do |mysqlserver|
      mysqlserver.vm.box = "fnando/dev-bionic64"
      mysqlserver.vm.network "private_network", ip: "10.80.4.10"
      mysqlserver.vm.network "forwarded_port", guest: 3306, host: 3306
  
      mysqlserver.vm.provider "virtualbox" do |vb|
        vb.name = "mysqlserver"
      end
  
      mysqlserver.vm.provision "shell", inline: $script_mysql
    end



  end
