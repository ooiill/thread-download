#!/usr/bin/env bash

current=$(cd `dirname $0`; pwd)
source ${current}/library.sh

###
#
# 执行多任务
# 
# param ${1} 任务
# param ${2} 任务数
# param ${3} 进程数
# return void
#
###
function thread()
{

    # 任务
    mission=${1}

    # 任务数
    missionNum=${2}

    # 线程数
    threadNum=${3}

    if [ ${threadNum} -gt ${missionNum} ]
        then
        threadNum=${missionNum}
    fi

    ###

    # 监听 ctrl+c 的信号 2
    # 监听到时执行 exex ... 来关闭 fd5 与 fifo 文件的绑定
    # 关闭读/写绑定必须分开写，不能像绑定的时候使用 <> 符号
    trap "exec 5>&-;exec 5<&-;exit 0" 2

    ###

    fileName='/tmp/thread-download-fifofile'
    
    # 创建 fifo 文件
    mkfifo ${fileName}
    
    # 将 fd5 与 fifo 文件绑定读写功能
    # 该值的取值范围为 0~9
    # 系统占用的 0，1，2 分别为 stdin，stdout，stderr
    # 如果不绑定流 fd5 在读或写的时候可能会出现停滞现象
    exec 5<>${fileName}
    rm -f ${fileName}

    ###

    # 向流 fd5 写入指定线程数个空行
    for((n=1;n<=${threadNum};n++))
    do
        echo >&5
    done

    ###

    # 执行任务
    for((i=1;i<=${missionNum};i++))
    do
        # 从流 fd5 中读取一个空行
        read -u5
        {
            # 执行相应的任务
            color 32 ${i}/${missionNum} 'begin of the ' ' '`date "+%H:%M:%S"`
            
            # 任务方法所需的参数
            ${mission} ${i}
            sleep 0.1

            # 将使用完的空行进行重置填充
            echo >&5
        }& # 将任务放置在后台运行
    done

    ###

    # 等待后台的这批任务全部执行完成
    wait

    # 关闭文件流 fd5 的读/写绑定
    exec 5>&-
    exec 5<&-
}

###
#
# 下载文件
#
# param ${1} 文件地址
# param ${2} 保存目录，默认当前目录
# return boolean
#
###
function download()
{

    # 文件名
    file=${1}

    # 保存到指定目录
    saveDirectory=${2}

    # 引用地址
    referer=`test "${3}" = "null" && echo '' || echo " --referer=${3}"`

    # 变量 i
    i=${4}

    # 公共参数
    # -t 重试次数，-T 超时时长，-c 断点续传，-q 静默下载
    # common="-t 3 -T 120 -cq"
    common="--no-check-certificate --user-agent=\"Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.8.1.6) Gecko/20070725 Firefox/2.0.0.6\" -cq${referer}"

    # 自动重命名
    if [ "${saveDirectory}" == "auto" ]
    then
        # 要下载的文件 url
        line=`sed -n ${i}p ${file}`

        targetFile=`echo ${line} | awk '{print $1}'`
        
        fileNewName=""
        line=(${line})

        for ((i=1; i<${#line[@]}; i++))
        do
            fileNewName="${fileNewName} ${line[${i}]}"
        done
        fileNewName=${fileNewName:1}

        if [ ${#targetFile} -gt 0 ]
        then
            fileNewPath=`dirname "${fileNewName}"`
            mkdir -p "${fileNewPath}"

            # -O 重命名
            wget ${common} "${targetFile}" -O "${fileNewName}"
        fi
    else
        # 要下载的文件 url
        targetFile=`sed -n ${i}p ${file}`

        if [ ${#targetFile} -gt 0 ]
        then
            mkdir -p ${saveDirectory}

            # 不重命名

            # -P 指定保存目录
            # wget ${common} "${targetFile}" -P "${saveDirectory}"

            # 重命名
            fileNewName=`echo ${targetFile} | md5`
            fileName=`basename ${targetFile}`
            suffix=${fileName##*.}
            
            # -O 重命名
            wget ${common} "${targetFile}" -O "${saveDirectory}/${fileNewName}.${suffix}"
        fi
    fi
}

###
#
# 参数处理
# 
# f:    配置文件 file
# d     保存目录 directory
# n     线程数量 number
#
###

while [ "${1}" ]
do
    case "${1}" in
        -f|--file) 
            file="${2}"
            shift 2
            ;;
        -d|--directory)
            directory="${2}"
            shift 2
            ;;
        --number)
            number="${2}"
            shift 2
            ;;
        -r|--referer)
            referer="${2}"
            shift 2
            ;;
        *)
            shift
            break
            ;;
    esac
done

directory=${directory-~/Downloads/}
number=${number-100}
referer=${referer-null}

# 判断文件是否存在
if [ ! -e "${file}" -o ! -s "${file}" ]
    then
    color 31 "File ${file} don't exists or blank."
    exit 1
fi

# 统计文件的总行数 - 任务数
missionNum=`wc -l ${file} | awk '{print $1}'`
missionNum=`expr ${missionNum} + 1`

thread "download ${file} ${directory} ${referer}" ${missionNum} ${number}

# USE
# ./main.sh --file picture --directory ~/Download/abc/ --number 100

# -- eof --
