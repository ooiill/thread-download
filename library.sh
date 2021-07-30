#!/usr/bin/env bash

##
#
# 去除字符串两端空格
# 
# param ${1} 字符串
#
##
function trim()
{
    str=${1}

    echo "${str}" | grep -o "[^ ]\+\( \+[^ ]\+\)*"
}

##
#
# 获取 ini 配置的所有 item
# 
# param ${1} ini 文件路径
#
##
function items()
{
    file=${1}
    items=`cat ${file} | grep -E '^\[.*\]$' | cut -d '[' -f2 | cut -d ']' -f1`

    echo ${items}
}

##
#
# 获取 ini 配置的所有指定的 key
# 
# param ${1} ini 文件路径
# param ${2} key 名称
#
##
function keys()
{
    file=${1}
    key=${2-name}
    spearator=${3- }
    keys=''

    item=`items ${file}`
    for i in ${item[*]}
    do
        _key=`ini ${file} ${i} ${key} ${i}`
        keys="${keys}${spearator}${_key}"
    done

    echo ${keys:1}
}

##
#
# 获取 ini 指定 item 和 key 的配置值
# 
# param ${1} ini      文件路径
# param ${2} item     名称
# param ${3} key      名称
# param ${4} default  默认值
#
##
function ini()
{
    file=${1}
    item=${2}
    key=${3}
    default=${4}
    var=`sed -n "/\[${item}\]/,/\[.*\]/p" ${file} | grep -v "\[${item}\]" | grep "^${key}[ ]*="`

    if [ -z "${var}" ]
    then
        echo ${default}
        exit 1
    fi

    var=`echo ${var} | sed "s/^${key}[ ]*=//"`

    echo ${var}
}

##
#
# 字符串格式化成颜色输出
# 
# param ${1} 颜色数值
# param ${2} 字符串内容
# param ${3} 开始标记
# param ${4} 结束标记
#
##
function color()
{
    color=${1}
    message=${2}
    begin=${3}
    end=${4}
    backendColor=${5-1}

    echo -e "${begin}\033[${backendColor};${color}m${message}\033[0;1m${end}"
}

##
#
# 菜单列表打印
# 
# param ${1} 菜单列表
# param ${2} 标题
# param ${3} 是否清屏 - 默认是
# param ${4} 默认选择
# param ${5} 仅打印列表
#
##
function menu()
{

    menu=${1}
    title=${2-"All of the menu."}
    cls=${3-"yes"}
    default=${4}
    printOnly=${5-"no"}

    # 定义要用的变量
    i=1

    # 清屏并提示标题
    if [ "${cls}" == "yes" ]
    then
        clear
    fi
    
    if [ "${default}" != "" ]
    then
        _menu=(${menu})
        title="${title} [default: ${_menu[`expr ${default} - 1`]}]"
    fi
    
    color 30 "${title}" '\n' '\n'

    # 遍历打印菜单
    for _item in ${menu[*]}
    do
        if [ ${#i} -lt 2 ]
        then
            _i="0${i}"
        else
            _i=${i}
        fi
        color 32 "  [${_i}]" '' '\c'
        echo -n " --- "
        color 34 "${_item}"
        ((i++))
    done
    
    echo
    if [ "${printOnly}" == "yes" ]
    then
        return
    fi
    
    max=`expr ${i} - 1`
    number=`inputint "Please select a index" ${max} ${default}`
    if [ "$?" != 0 ]
    then
        echo -e "${number}"
        exit
    fi
    
    return `expr ${number} - 1`
}

##
#
# 输入并接受整数
# 
# param ${1} 提示标题
# param ${2} 最大值
# param ${3} 默认值
# param ${4} 是否多选 - 默认否
#
##
function inputint()
{
    title=${1}
    max=${2}
    default=${3}
    checkbox=${4-"no"}
    
    # 提示输入数字进行选择
    if [ "${checkbox}" == "yes" ]
    then
        title="${title}, allows multiple by space"
    fi
    
    declare -a number
    read -p "${title} : " number
    number=(${number})
    
    if [ "${checkbox}" != "yes" -a ${#number[*]} -gt 1 ]
    then
        color 31 "not allows multiple selection." '\n' '\n\a'
        exit 2
    fi
    
    if [ ${#number[*]} -eq 0 -a -n "${default}" ]
    then
        number=${default}
    fi
    
    if [ ${#number[*]} -eq 0 ]
    then
        color 31 "The index is illegal, must be number than in 1 to ${max}." '\n' '\n\a'
        exit 2
    fi
    
    # 验证输入
    for j in ${number[*]}
    do
        expr ${j} "+" 1 &> /dev/null
        if [ ! $? -eq 0 ]
        then
            color 31 "The index ${j} is illegal, must be number." '\n' '\n\a'
            exit 2
        fi
        
        if [ ${j} -lt 1 -o ${j} -gt ${max} ]
        then
            color 31 "The index ${j} is illegal, must in 1 to ${max}." '\n' '\n\a'
            exit 2
        fi
    done
    
    echo ${number[*]}
}

##
#
# 判断指定元素是否在数组中
# 
# param ${1} 数组
# param ${2} 指定元素
#
##
function inarray()
{
    local n=$#
    local value=${!n}

    for ((i=1;i < $#;i++))
    do
        if [ "${!i}" == "${value}" ]
        then
            echo "yes"
            exit 0
        fi
    done
    echo "no"
}

##
#
# 格式化一组键值对
# 
# param ${1} 键
# param ${2} 值
#
##
function format_kv()
{
    key=${1}
    val=${2}

    echo "${key}  " | awk -F '#' '{printf ("\033[1;32m %25s\033[0;0m",${NF})}'
    echo ${val}
}

##
#
# 颜色列表
#
##
function show_color()
{
    # background color
    for (( b = 40; b <= 47; b++ )); do
        color 37 " background = ${b} " "\n\t" "" ${b}
    done

    # front color
    for (( f = 30; f <= 37; f++ )); do
        end=`test ${f} == 37 && echo "\n" || echo ""`
        color ${f} " front = ${f} " "\n\t" "${end}" 1
    done
}

##
#
# 聚合指定后缀的文件
#
# param ${1} 扩展名
# param ${2} 资源目录
# param ${3} 聚合目标目录
#
##
function togger_file()
{
    extend=${1}
    sourceDir=${2}
    targetDir=${3-~/Downloads}

    standardIFS=${IFS}
    IFS=$'\n'

    for i in `find "${sourceDir}" -name "*.${extend}" -type f -exec ls {} \;`
    do
        cp ${i} ${targetDir}/
    done

    IFS=${standardIFS}

    color 32 "Action completed."
}

