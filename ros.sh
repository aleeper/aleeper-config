############################
# bash shortcuts
# originally designed for fast editing of one monolithic bash file...
# maybe not needed anymore if I'm using correct workspace management.
alias rebash='. ~/.bashrc'
alias editbash='vim ~/.bashrc'
alias backbash='cp ~/.bashrc ~/.bashrc.back'

# Wrap make and rosmake so that they alert me with a sound when they are done
make() 
{ 
/usr/bin/make $1
if [ $? -eq 0 ]; then    
  aplay $HOME/aleeper-config/sounds/scifi002-trim.wav;
else
  aplay $HOME/aleeper-config/sounds/banana-peel.wav;
fi
}
playrosmake() { rosmake; aplay $HOME/sounds/scifi002.wav; }

backup() { cp $1 $1.bak; }
alias gitinfo='. /home/$USER/.git_info.sh'

# time saving :)
imview () { rosrun image_view image_view image:=$1; } 
dispview () { rosrun image_view disparity_view image:=$1; }

rviz() { rosrun rviz rviz; }
dashboard() { rosrun pr2_dashboard pr2_dashboard; }
reconfigure() { rosrun dynamic_reconfigure reconfigure_gui; }
manager() { rosrun pr2_controller_manager pr2_controller_manager; }
sixaxis() { roslaunch pr2_teleop teleop_joystick.launch; }
alias gtopic='rostopic list | sort -u | grep'

# directory navigation
alias kk='cd -'
alias up='cd ..'
alias upp='cd ../..'
alias uppp='cd ../../..'
alias upppp='cd ../../../..' 
alias uppppp='cd ../../../../..' 

# Computers (hosts)
alias jks-g51='export ROS_MASTER_URI=http://jks-g51:11311'
alias stair4a='export ROS_MASTER_URI=http://stair4a:11311'
alias jks-al='export ROS_MASTER_URI=http://jks-al:11311'
alias jks-prbase='export ROS_MASTER_URI=http://jks-prbase:11311'
alias ael-w530='export ROS_MASTER_URI=http://ael-w530:11311'
alias btt='export ROS_MASTER_URI=http://btt:11311'
alias prj='export ROS_MASTER_URI=http://prj:11311'
alias prk='export ROS_MASTER_URI=http://prk:11311'
alias pri='export ROS_MASTER_URI=http://pri:11311'
alias prl='export ROS_MASTER_URI=http://prl:11311'
alias prm='export ROS_MASTER_URI=http://prm:11311'
alias prn='export ROS_MASTER_URI=http://prn:11311'
alias pro='export ROS_MASTER_URI=http://pro:11311'
alias prp='export ROS_MASTER_URI=http://prp:11311'
alias prq='export ROS_MASTER_URI=http://prq:11311'
alias prg='export ROS_MASTER_URI=http://prg1:11311'
alias prf='export ROS_MASTER_URI=http://prf1:11311'
alias wbr='export ROS_MASTER_URI=http://wbr:11311'
alias hsim='export ROS_MASTER_URI=http://hsim:11311'

alias ls='ls --color=auto'
export PATH=$HOME/aleeper-config/bin:/usr/local/sbin:/usr/sbin:/sbin:$PATH
#ssh-agent sh -c 'ssh-add < /dev/null && bash'

function ws()
{
    cd $HOME/ros/"$1"
    export ROS_WS=$PWD
    export ROS_WORKSPACE=$ROS_WS
    if [ -f setup.bash ]; then
        echo "Sourcing setup.bash"
        source setup.bash
    fi;

    # create a ros environment loader
    echo "Creating env loader"
    make_env_loader.py $ROS_WS
    export ROS_ENV_LOADER=$ROS_WS/env.sh
}

function build_moveit()
{
 rosmake pr2_arm_kinematics ompl_interface_ros planning_request_adapter_plugins chomp_interface_ros sbpl_interface_ros pr2_moveit_controller_manager pr2_moveit_sensor_manager moveit_visualization_ros moveit_rviz_plugin planning_request_adapter_plugins
}

function fuerte()
{
  source /opt/ros/fuerte/setup.bash
}

function groovy()
{
  source /opt/ros/groovy/setup.bash
}

function demos()
{
  source ~/demos/setup.bash
}

function groovy_ws()
{
  source ~/ros/groovy_precise/catkin_ws/build/devel/setup.bash
  export ROS_WORKSPACE=~/ros/groovy_precise/catkin_ws
}

function heaphy()
{
  source /opt/ros/electric/setup.bash
  export ROS_PACKAGE_PATH=~/ros/heaphy_overlay:$ROS_PACKAGE_PATH
}
