function dri --wraps='docker images' --wraps='docker images -a' --description 'alias dri=docker images -a'
  docker images -a $argv; 
end
