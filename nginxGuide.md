1. Instalar

```
sudo apt install nginx -y
```

2. iniciar server: sudo /etc/init.d/nginx start

(Esto es solo para probar si funciona el sitio al acceder a la ip), puedes ver tu ip con el siguiente comando:

```
hostname -I
```

3. modificar /etc/nginx/sites-available/default :

```
	location / {
        proxy_pass http://localhost:4000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
```

4. reiniciar nginx:
```
sudo systemctl restart nginx
```
(si no se habia inicalizado, solo correr el comando de start)


