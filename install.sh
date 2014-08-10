#!/bin/bash


USER_MONGO="mongodb"
GROUP_MONGO="mongodb"
WORK_PATH="/tmp/mongo"
DB_PATH="${WORK_PATH}/data"
LOG_PATH="${WORK_PATH}/log"
RUN_PATH="${WORK_PATH}/run"
CFG_PATH="${WORK_PATH}/config"
ROUTE_PORT="27018"
CFG_PORT="27019"
SHARD_PORT="27020"
ARBIT_PORT="27021"

function set_val_in_template {
    local var_name=$1
    local var_value=$2
    local file_path=$3
    
    sed -i s#%$var_name%#"$var_value"# $file_path
}

function dir_structure_init {
    mkdir -p $WORK_PATH
    mkdir -p $DB_PATH
    mkdir -p $LOG_PATH    
    mkdir -p $RUN_PATH
    mkdir -p $CFG_PATH
}

function dir_set_permission {
    chown -R $USER_MONGO:$GROUP_MONGO $WORK_PATH
}



function generate_init_file {
    echo "copy template init file"
    cp $tpl_init_file $init_file
    chmod +x $init_file
    
    set_val_in_template config_file $config_file $init_file  
    set_val_in_template name_server $name_server $init_file
    set_val_in_template log_file $log_file $init_file
    set_val_in_template pid_file $pid_file $init_file
    set_val_in_template dbpath $dbpath $init_file
}

function mongo_config_server_init {
    dir_structure_init
    
    local name_server=$1
    local bind_ip=$2
    
    local tpl_file_name="mongod_config.tpl"
    local tpl_file="templates/${tpl_file_name}"
    local tpl_init_name="mongod_init.tpl"
    local tpl_init_file="templates/${tpl_init_name}"
    local init_file="/etc/init.d/${name_server}"
    local log_file="${LOG_PATH}/${name_server}.log"    
    local pid_file="${RUN_PATH}/${name_server}.pid"  
    local config_file="${WORK_PATH}/config/${name_server}.conf"  
    local dbpath="${DB_PATH}/${name_server}"
    
    echo "create log ${log_file}"
    touch $log_file
    echo "create pid ${pid_file}"
    touch $pid_file    
    echo "create dbpath ${name_server}"    
    mkdir -p $dbpath

    echo "copy template config server"        
    cp $tpl_file $config_file
    
    echo -e "\n\ninit config ${name_server} port $CFG_PORT"        
    set_val_in_template log_file $log_file $config_file 
    set_val_in_template pid_file $pid_file $config_file
    set_val_in_template dbpath $dbpath $config_file
    set_val_in_template bind_ip "$bind_ip" $config_file    
    set_val_in_template port $CFG_PORT $config_file      
    
    generate_init_file      
    
    echo -e "\n\nshow config $config_file"
    cat $config_file
    
    dir_set_permission
}

function mongo_route_server_init {
    dir_structure_init
    
    local name_server=$1
    local bind_ip=$2
    local config_server_list=$3
    
    local tpl_file_name="mongod_route.tpl"
    local tpl_file="templates/${tpl_file_name}"
    local tpl_init_name="mongod_route_init.tpl"
    local tpl_init_file="templates/${tpl_init_name}"
    local init_file="/etc/init.d/${name_server}"
    local log_file="${LOG_PATH}/${name_server}.log"    
    local pid_file="${RUN_PATH}/${name_server}.pid" 
    local config_file="${WORK_PATH}/config/${name_server}.conf"  
    local dbpath="${DB_PATH}/${name_server}"
    
    echo "create log ${log_file}"
    touch $log_file
    echo "create pid ${pid_file}"
    touch $pid_file    
    echo "create dbpath ${name_server}"    
    mkdir -p $dbpath
    
    echo "copy template config server"        
    cp $tpl_file $config_file
    
    echo -e "\n\ninit config ${name_server} port $ROUTE_PORT"        
    set_val_in_template log_file $log_file $config_file 
    set_val_in_template pid_file $pid_file $config_file
    set_val_in_template dbpath $dbpath $config_file
    set_val_in_template bind_ip "$bind_ip" $config_file    
    set_val_in_template port $ROUTE_PORT $config_file      
    set_val_in_template config_server_list "$config_server_list" $config_file      
    
    generate_init_file  
    
    echo -e "\n\nshow config $config_file"
    cat $config_file
    
    
    dir_set_permission
}


function mongo_shard_server_init {
    dir_structure_init
    
    local name_server=$1
    local bind_ip=$2
    local repl_set=$3
    
    local tpl_file_name="mongod_shard.tpl"
    local tpl_file="templates/${tpl_file_name}"
    local tpl_init_name="mongod_init.tpl"
    local tpl_init_file="templates/${tpl_init_name}"
    local init_file="/etc/init.d/${name_server}"
    local log_file="${LOG_PATH}/${name_server}.log"    
    local pid_file="${RUN_PATH}/${name_server}.pid" 
    local config_file="${WORK_PATH}/config/${name_server}.conf"  
    local dbpath="${DB_PATH}/${name_server}"
    
    echo "create log ${log_file}"
    touch $log_file
    echo "create pid ${pid_file}"
    touch $pid_file    
    echo "create dbpath ${name_server}"    
    mkdir -p $dbpath
    
    echo "copy template config server"        
    cp $tpl_file $config_file
    
    echo -e "\n\ninit shard ${name_server} port ${SHARD_PORT}"       
     
    set_val_in_template port $SHARD_PORT $config_file      
    set_val_in_template log_file $log_file $config_file 
    set_val_in_template pid_file $pid_file $config_file
    set_val_in_template dbpath $dbpath $config_file
    set_val_in_template bind_ip "$bind_ip" $config_file    
    set_val_in_template repl_set "$repl_set" $config_file 
    
    generate_init_file  
    
    echo -e "\n\nshow config $config_file"
    cat $config_file
    
    dir_set_permission
    

}

# select action

#
#> sh.addShard(«rs01//mongo01-rs01:27017,mongo02-rs01:27017»)
#> sh.addShard(«rs02/mongo01-rs02:27017,mongo02-rs02:27017»)
#> sh.status()
#

#
#> use filestore
#> sh.enableSharding(«filestore»)
#> sh.shardCollection(«filestore.fs.chunks», { files_id: 1, n: 1 })
#> sh.status()
#
#
if [[ $1 == '-cfg-server' ]]; then
    shift
    mongo_config_server_init $1 "$2"
elif [[ $1 == '-route-server' ]]; then
    shift
    mongo_route_server_init $1 "$2" "$3"
elif [[ $1 == '-shard-server' ]]; then
    shift
    mongo_shard_server_init $1 "$2" "$3" 
else
  echo "Please select action"
  echo "  -cfg-server %name_server% %bind_ip% "  
  echo "  -cfg-server mongo_c_1 \"127.0.0.1,192.168.0.2\""
  echo ""
  echo "  -route-server %name_server% %bind_ip% %config_server_list%"  
  echo "  -route-server mongo_r_1 \"127.0.0.1,192.168.0.2\" \"mongo-c-1:$CFG_PORT, mongo-c-2:$CFG_PORT, mongo-c-2:$CFG_PORT\""    
  echo ""
  echo "  -shard-server %name_server% %bind_ip% %repl_set% "    
  echo "  -shard-server mongo_s_1 \"127.0.0.1,192.168.0.2\" session_set01 "     
  echo "" 
fi
