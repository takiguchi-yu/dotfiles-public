function dr --wraps=docker --wraps='docker images' --description 'alias dr=docker'
  docker $argv; 
end
