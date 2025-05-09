# Ponto

Ponto Eletrônico é um aplicativo desenvolvido em Flutter para gerenciar o registro de ponto de funcionários de forma prática e eficiente. Ele oferece funcionalidades tanto para administradores quanto para funcionários, permitindo o controle de horários de trabalho, localização e gerenciamento de dados diretamente pelo aplicativo.

## Funcionalidades Principais
### Para Funcionários
```dart
-Login Seguro:               Acesso ao painel do funcionário com validação de dados.
-Registro de Ponto:          Realize check-in e check-out com registro automático da localização.
-Visualização de Horários:   Exibe o horário de check-in, check-out e as horas trabalhadas no dia e no mês.
-Interface Intuitiva:        Painel simplificado para facilitar o uso diário.
```

### Para Administradores
```dart
-Cadastro de Funcionários:       Adicione novos funcionários ao sistema com nome e telefone.
-Gerenciamento de Funcionários:  Visualize a lista de funcionários cadastrados e seus registros de ponto.
-Exibição de Localização:        Veja a localização do funcionário no momento do registro de ponto em um mapa interativo.
-Controle de Horas Trabalhadas:  Monitore as horas trabalhadas por mês de cada funcionário.
-Logout Seguro:                  Logout como único meio de retorno ao menu principal.
```

### Funcionalidades Gerais
```dart
-Integração com Firebase:    Gerenciamento de dados em tempo real usando o Firebase Firestore.
-Geolocalização:             Registro da localização do funcionário no momento do check-in e check-out.
-Google Maps:                Exibição de localização em mapas interativos.
-Design Responsivo:          Interface adaptada para diferentes tamanhos de tela.
```
## Tecnologias Utilizadas
```dart
->Flutter:              Framework para desenvolvimento multiplataforma.
->Firebase:             Gerenciamento de autenticação e banco de dados em tempo real.
->Google Maps API:      Exibição de mapas e localização.
->Geolocator:           Captura de localização do dispositivo.
->Shared Preferences:   Armazenamento local de dados do administrador.
```
---
### Como Usar
**Funcionário:**
<ol>
  <li>Faça login com seu nome e telefone.</li>
  <li>Registre seu ponto (check-in e check-out) e acompanhe suas horas trabalhadas.</li>
</ol>

**Administrador:**
<ol>
  <li>Faça login ou cadastre-se como administrador.</li>
  <li>Gerencie os funcionários, visualize registros de ponto e acompanhe a localização em tempo real.</li>
</ol>

## Público-Alvo
Este aplicativo é ideal para pequenas e médias empresas que desejam gerenciar o registro de ponto de seus funcionários de forma digital, prática e eficiente.
