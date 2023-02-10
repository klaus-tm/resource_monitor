#!/bin/bash

r0=0
t0=0
contor_log=1
GraphCPU=(0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0)
GraphMEM=(0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0)

getCpuUsage(){
	NRCPUS=$(nproc --all)

	ps -eo %cpu --sort=-%cpu >> cpu
	sed -i '1d' ./cpu

	CPU=0.0
	CPU=$(awk ' { CPU += $1 } END { print CPU-CPU%1 } ' cpu)

	if [ -z "$1" ]
	then
		echo "CPU:"
		echo "  usage: $((CPU/NRCPUS))%"
		echo "  available: $((100-(($CPU/$NRCPUS))))%"
	else
		echo "CPU:" >> $1
		echo "  usage: $((CPU/NRCPUS))%" >> $1
		echo "  available: $((100-(($CPU/$NRCPUS))))%" >> $1
	fi

	for((i=0; i<${#GraphCPU[@]}-1; i++)); do
		GraphCPU[i]=${GraphCPU[i+1]}
	done
	GraphCPU[${#GraphCPU[@]}-1]=$((CPU/NRCPUS))
	rm cpu
}

getMemUsage(){
	ps -eo %mem --sort=-%mem >> mem
	sed -i '1d' ./mem

	MEM=0.0
	MEM=$(awk ' { MEM += $1 } END { print MEM-MEM%1 } ' mem)

	if [ -z "$1" ]
	then
		echo "Memory:"
		echo "  usage: $MEM%"
		echo "  available: $((100-$MEM))%"
	else
		echo "Memory:" >> $1
		echo "  usage: $MEM%" >> $1
		echo "  available: $((100-$MEM))%" >> $1
	fi

        for((i=0; i<${#GraphMEM[@]}-1; i++)); do
                GraphMEM[i]=${GraphMEM[i+1]}
        done
        GraphMEM[${#GraphMEM[@]}-1]=$MEM


	rm mem
}

getIOUsage(){
	iostat -d | awk ' { print $3 }' >> io_read
	iostat -d | awk ' { print $4 }' >> io_write

	sed -i '1,3d' ./io_read io_write
	IO_READ=0.0
	IO_WRITE=0.0
	sed -i 's/,/./g' ./io_read io_write

	if [ -z "$1" ]
	then
		echo "I/O usage:"
		echo "  Input: $(awk ' { IO_READ += $1 } END { print IO_READ } ' io_read)kb/s"
		echo "  Output: $(awk ' { IO_WRITE += $1 } END { print IO_WRITE } ' io_write)kb/s"
	else
		echo "I/O usage:" >> $1
		echo "  Input: $(awk ' { IO_READ += $1 } END { print IO_READ } ' io_read)kb/s" >> $1
		echo "  Output: $(awk ' { IO_WRITE += $1 } END { print IO_WRITE } ' io_write)kb/s" >> $1
	fi

	rm io_read io_write
}

getNetworkBandwidth(){
	net=$(ip -o link sh up | awk 'BEGIN{FS=": "} $2!="lo" {print $2}')
	r=$(cat /sys/class/net/$net/statistics/rx_bytes)
	t=$(cat /sys/class/net/$net/statistics/tx_bytes)

	if [ -z $1 ]
	then
		echo "Bandwidth:"
		echo "  received: $(((($r-$r0))/1024))kb/s"
		echo "  transmitted: $(((($t-$t0))/1024))kb/s"
	else
		echo "Bandwidth:" >> $1
		echo "  received: $(((($r-$r0))/1024))kb/s" >> $1
		echo "  transmitted: $(((($t-$t0))/1024))kb/s" >> $1
	fi

	r0=$r
	t0=$t
}

createLogFile(){
	getCpuUsage log_proiect/$contor_log.txt
	getMemUsage log_proiect/$contor_log.txt
	getIOUsage log_proiect/$contor_log.txt
	getNetworkBandwidth log_proiect/$contor_log.txt

	((contor_log=contor_log+1))
}

CPUGraph(){
	tput cup 1 30
	echo "CPU usage graph"
        tput cup 10 25
        echo "0"
        tput cup 6 25
        echo "50"
        tput cup 2 25
        echo "100______________________________"

	for height in 8 7 6 5 4 3 2 1; do
		tput cup $((11-$height)) 28
		for i in "${GraphCPU[@]}";
                do
                        if [ $i -lt $((100*$(($height-1))/8)) ]; then
                                printf "_"
                        elif [ $i -ge $((100*$height/8)) ]; then
                                printf "█"
                        elif [ $(($i-100*$(($height-1))/8)) -eq 0  ]; then
                                printf "_"
                        elif [ $(($i-100*$(($height-1))/8)) -le 4  ]; then
				printf "░"
                        elif [ $(($i-100*$(($height-1))/8)) -le 8  ]; then
                                printf "▒"
                        elif [ $(($i-100*$(($height-1))/8)) -le 12  ]; then
                                printf "▓"
                        else
                                printf "█"
                        fi
                done
		height=$height-1
	done
}

MEMGraph(){
        tput cup 14 30
        echo "Memory usage graph"
        tput cup 23 25
        echo "0"
        tput cup 19 25
        echo "50"
        tput cup 15 25
        echo "100______________________________"

        for height in 8 7 6 5 4 3 2 1; do
                tput cup $((24-$height)) 28
                for i in "${GraphMEM[@]}";
                do
                        if [ $i -lt $((100*$(($height-1))/8)) ]; then
                                printf "_"
                        elif [ $i -ge $((100*$height/8)) ]; then
                                printf "█"
                        elif [ $(($i-100*$(($height-1))/8)) -eq 0  ]; then
                                printf "_"
                        elif [ $(($i-100*$(($height-1))/8)) -le 4  ]; then
                                printf "░"
                        elif [ $(($i-100*$(($height-1))/8)) -le 8  ]; then
                                printf "▒"
                        elif [ $(($i-100*$(($height-1))/8)) -le 12  ]; then
                                printf "▓"
                        else
                                printf "█"
                        fi
                done
                height=$height-1
        done
}






contor_sec=0
rm -r log_proiect
mkdir log_proiect
while :
do
	clear
	((contor_sec=contor_sec+1))
	getCpuUsage
	getMemUsage
	getIOUsage
	getNetworkBandwidth
	CPUGraph
	MEMGraph
	if [ $contor_sec == 60 ]
	then
		createLogFile
		contor_sec=0
	fi
	sleep 1
done
