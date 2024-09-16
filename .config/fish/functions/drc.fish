function drc --wraps='docker container ls -a' --description 'alias drc=docker container ls -a'
  docker container ls -a $argv; 
end
