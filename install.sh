#!/bin/bash


USER_MONGO="mongodb"
GROUP_MONGO="mongodb"
WORK_PATH="/tmp/mongo"
DB_PATH="${WORK_PATH}/data"
LOG_PATH="${WORK_PATH}/log"
RUN_PATH="${WORK_PATH}/run"
CFG_PATH="${WORK_PATH}/config"

function set_val_in_template {
    local var_name=$1
    local var_value=$2
    local file_path=$3
    
    sed -i s/%$var_name%/"${var_value}"/ $file_path
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


function mongo_config_server_init {
    dir_structure_init
    
    local name_server=$1
    local bind_ip=$2
    
    local tpl_file_name="mongod_config.tpl"
    local tpl_file="templates/${tpl_file_name}"
    local log_file="${LOG_PATH}/${name_server}.log"    
    local pid_file="${RUN_PATH}/${name_server}.log"  
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
    
    echo "init config ${name_server}"        
    set_val_in_template log_file $log_file $config_file 
    set_val_in_template pid_file $pid_file $config_file
    set_val_in_template dbpath $dbpath $config_file
    set_val_in_template bind_ip $bind_ip $config_file    
    
    dir_set_permission
}

# select action

if [[ $1 == '-cfg-server' ]]; then
    shift
    mongo_config_server_init $1 $2
elif [[ $1 == '-route-server' ]]; then
    shift
    echo "route"
elif [[ $1 == '-shard-server' ]]; then
    shift
    echo "shard"    
else
  echo "-cfg-server %name_server% %bind_ip% "  
  echo "-route-server %name_server% %bind_ip% "  
  echo "-cfg-server %name_server% %bind_ip% "    
fi

# while [[ $# > 1 ]]
# do
# key="$1"
# shift
#
# case $key in
#     -c)
#         echo "cfg_server"
#         shift
#         ;;
#     *)
#         echo "please select setup server"
#         ;;
# esac
# done