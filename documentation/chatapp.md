### Creare una nuova app Rails.
```
rails new chatapp
cd chatapp
```

### Creare un modello utente e eseguirne la migrazione.
``` ruby
rails g model User username
rails db:migrate
```

Successivamente, aggiungiamo una validazione univoca per il nome utente, poiché desideriamo che tutti i nomi utente siano univoci per i rispettivi proprietari. Creiamo anche uno scope per recuperare tutti gli utenti tranne l'utente corrente per la nostra lista utenti, poiché non vogliamo che un utente chatti con se stesso.

```ruby
#app/models/user.rb
class User < ApplicationRecord
  validates_uniqueness_of :username
  scope :all_except, ->(user) { where.not(id: user) }
end

```

### Creare un modello "Room" per la nostra chat.

Una stanza per la nostra chat ha un nome e può essere una stanza di chat privata (per chat private tra due utenti) o pubblica (accessibile a tutti). Per indicare ciò, aggiungiamo una colonna `is_private` alla nostra tabella delle stanze (room).

```ruby
rails g model Room name:string is_private:boolean
```

Prima di eseguire la migrazione di questo file, aggiungeremo un valore predefinito alla colonna `is_private` in modo che tutte le stanze create siano pubbliche per impostazione predefinita, a meno che non venga specificato diversamente.

```ruby
class CreateRooms < ActiveRecord::Migration[7.0]
  def change
    create_table :rooms do |t|
      t.string :name
      t.boolean :is_private, default: :false

      t.timestamps
    end
  end
end

```

Dopo questo passaggio, eseguiamo la migrazione del nostro file utilizzando il comando `rails db:migrate`. È anche necessario aggiungere la validazione di unicità per la proprietà name e uno scope per recuperare tutte le stanze pubbliche per la nostra lista di stanze.

```ruby
#app/models/room.rb
class Room < ApplicationRecord
  validates_uniqueness_of :name
  scope :public_rooms, -> { where(is_private: false) }
end
```

### Aggiungere lo stile (styling).

Per aggiungere uno stile minimo a questa app, aggiungeremo il bootstrap CDN al nostro file `application.html.erb`.

```ruby
<link rel="stylesheet" href="https://stackpath.bootstrapcdn.com/bootstrap/4.3.1/css/bootstrap.min.css" integrity="sha384-ggOyR0iXCbMQv3Xipma34MD+dH/1fQ784/j6cY/iJTQUOhcWr7x9JvoRxT2MZw1T" crossorigin="anonymous">

```

### Aggiungere l'autenticazione (base)

```ruby
#app/controllers/application_controller.rb
helper_method :current_user

def current_user
  if session[:user_id]
    @current_user  = User.find(session[:user_id])
  end
end

def log_in(user)
  session[:user_id] = user.id
  @current_user = user
  redirect_to root_path
end

def logged_in?
  !current_user.nil?
end

def log_out
  session.delete(:user_id)
  @current_user = nil
end

```

```ruby
#app/controllers/sessions_controller.rb
class SessionsController < ApplicationController

  def create
    user = User.find_by(username: params[:session][:username])
    if user
      log_in(user)
    else
      render 'new'
    end
  end

  def destroy
    log_out if logged_in?
    redirect_to root_path
  end

end
```

```ruby
#app/views/sessions/new.html.erb
<%= form_for (:session) do |f| %>
  <%= f.label :username, 'Enter your username' %>
  <%= f.text_field :username, autocomplete: 'off' %>
  <%= f.submit 'Sign in' %>
<% end %>

```

Aggiungere le seguenti route al file routes.rb.

```ruby
#routes.rb
Rails.application.routes.draw do
  get '/signin', to: 'sessions#new'
  post '/signin', to: 'sessions#create'
  delete '/signout', to: 'sessions#destroy'
end
```
### Creare il controller

Per creare il controller Rooms, utilizziamo il comando `rails g controller Rooms index`, e aggiungiamo le variabili per la lista di utenti e stanze al nostro metodo index.

```ruby
class RoomsController < ApplicationController
  def index
    @current_user = current_user
    redirect_to '/signin' unless @current_user
    @rooms = Room.public_rooms
    @users = User.all_except(@current_user)
  end
end
```

### Configurare le route

Aggiungere le route per le stanze (rooms), gli utenti (users) e la route principale (root) nel file routes.rb, in modo che la nostra pagina principale sia la pagina index che elenca tutte le stanze e gli utenti, consentendo di navigare in qualsiasi stanza desiderata.

``` ruby
#routes.rb
  resources :rooms
  resources :users
  root 'rooms#index'

```

### Configurare le viste

La nostra prima introduzione alla 'magia' di Turbo è la ricezione di aggiornamenti in tempo reale sulla nostra dashboard in caso di nuove stanze aggiunte o nuovi utenti registrati. Per ottenere questo, prima di tutto, creiamo due parziali: _room.html.erb per visualizzare ogni stanza e _user.html.erb per visualizzare ogni utente. Renderemo questa lista nel file index.html.erb che è stato creato quando è stato creato il RoomsController, poiché questa è la nostra pagina principale.

```ruby
# app/views/rooms/_room.html.erb
<div> <%= link_to room.name, room %> </div>
# app/views/users/_user.html.erb
<div> <%= link_to user.username, user %> </div>
```

Procediamo con il rendering di questi file nel nostro index.html.erb, non facendo riferimento direttamente a essi, ma rendendo le variabili che recuperano la collezione. Ricorda che nel nostro RoomsController, le variabili @users e @rooms sono già state definite.

```ruby
#app/views/rooms/index.html.erb
<div class="container">
  <h5> Hi <%= @current_user.username %> </h5>
  <h4> Users </h4>
  <%= render @users %>
  <h4> Rooms </h4>
  <%= render @rooms %>
</div>
```
Nella console, esegui i seguenti comandi:

```ruby
Room.create(name: 'music')
User.create(username: 'Antonino')
User.create(username: 'Elena')
```

Attiva il server Rails usando `rails s`. Ti verrà chiesto di effettuare l'accesso; fallo utilizzando il nome utente di uno degli utenti creati in precedenza e dovresti vedere la stanza appena creata e l'utente con cui non hai effettuato l'accesso, come mostrato nell'immagine qui sotto.

Inserire immagine

### Introduzione a Turbo( Seguire queste parte per applicazioni rails < 7 )

Per ottenere aggiornamenti in tempo reale, è necessario avere Turbo installato. È importante notare che questa gemma è configurata automaticamente per le applicazioni create con Rails 7 e versioni successive.

```ruby
bundle add turbo-rails
rails turbo:install
```

Esegui i seguenti comandi per avviare Redis:

```ruby
sudo apt install redis-server
# installs redis if you don't have it yet
rails turbo:install:redis
# changes the development Action Cable adapter from Async (the default one) to Redis
redis-server
# starts the server
```


Importa turbo-rails nel file application.js usando import "@hotwired/turbo-rails".

Successivamente, aggiungeremo istruzioni specifiche ai nostri modelli e chiederemo loro di trasmettere ogni nuova istanza aggiunta a un canale particolare. Questa trasmissione è effettuata da ActionCable, come vedremo a breve.

```ruby
#app/models/user.rb
class User < ApplicationRecord
  validates_uniqueness_of :username
  scope :all_except, ->(user) { where.not(id: user) }
  after_create_commit { broadcast_append_to "users" }
end
```
Qui, stiamo chiedendo al modello utente di trasmettere a un canale chiamato "users" dopo la creazione di ogni nuova istanza di utente.

``` ruby 
#app/models/room.rb
class Room < ApplicationRecord
  validates_uniqueness_of :name
  scope :public_rooms, -> { where(is_private: false) }
  after_create_commit {broadcast_append_to "rooms"}
end
```

Qui, stiamo anche chiedendo al modello della stanza di trasmettere a un canale chiamato "rooms" dopo la creazione di ogni nuova istanza di stanza.

Avvia la tua console se non è già in esecuzione, o utilizza il comando reload! se è già attiva. Dopo la creazione di una nuova istanza di uno qualsiasi di questi, vedrai che ActionCable trasmette l'istanza aggiunta al canale specificato come un turbo stream, utilizzando il parziale ad esso assegnato come template. Per una stanza appena aggiunta, trasmette il parziale _room.html.erb con valori corrispondenti alla nuova istanza aggiunta, come mostrato di seguito.

```ruby
irb(main):006> Room.create(name: 'Viaggi')
  TRANSACTION (0.1ms)  begin transaction
  Room Create (0.6ms)  INSERT INTO "rooms" ("name", "is_private", "created_at", "updated_at") VALUES (?, ?, ?, ?)  [["name", "Viaggi"], ["is_private", 0], ["created_at", "2023-12-20 04:28:03.520867"], ["updated_at", "2023-12-20 04:28:03.520867"]]
  TRANSACTION (1.9ms)  commit transaction
  Rendered rooms/_room.html.erb (Duration: 2.1ms | Allocations: 277)
[ActionCable] Broadcasting to rooms: "<turbo-stream action=\"append\" target=\"rooms\"><template><div><a href=\"/rooms/2\">Viaggi</a></div></template></turbo-stream>"
```


Il problema, tuttavia, è che il modello trasmesso non appare sulla dashboard. Ciò è dovuto al fatto che è necessario aggiungere un ricevitore della trasmissione alla nostra vista in modo che ciò che viene trasmesso da ActionCable possa essere ricevuto e aggiunto. Facciamo ciò aggiungendo un tag turbo_stream_from, specificando il canale da cui speriamo di ricevere la trasmissione. Come visto nell'immagine sopra, lo stream trasmesso ha un attributo target, e questo specifica l'id del contenitore a cui lo stream verrà aggiunto. Ciò significa che il modello trasmesso cercherà un contenitore con un id "rooms" a cui aggiungersi; pertanto, includiamo un div con l'id indicato nel nostro file index. Per ottenere questo, nel nostro file index.html.erb, sostituisci il `<%= render @users %> con:`

```ruby
<%= turbo_stream_from "users" %>
<div id="users">
  <%= render @users %>
</div>
```

e `<%= render @rooms %>` con:

```ruby
<%= turbo_stream_from "rooms" %>
<div id="rooms">
  <%= render @rooms %>
</div>
```

In questo momento, possiamo sperimentare la magia di Turbo. Possiamo aggiornare la nostra pagina e iniziare ad aggiungere nuovi utenti e stanze dalla console e vederli aggiunti alla nostra pagina in tempo reale. Evviva!!!

Stanco di creare nuove stanze dalla console? Aggiungiamo un modulo che consente agli utenti di creare nuove stanze.

```ruby
#app/views/layouts/_new_room_form.html.erb
<%= form_with(model: @room, remote: true, class: "d-flex" ) do |f| %>
  <%= f.text_field :name, class: "form-control", autocomplete: 'off' %>
  <%= f.submit data: { disable_with: false } %>
<% end %>
```

Nel modulo sopra, viene utilizzato @room, ma non è ancora stato definito nel nostro controller; quindi, lo definiamo e lo aggiungiamo al metodo index del nostro RoomsController.

```ruby
@room = Room.new

```

Quando viene cliccato il pulsante "create", verrà instradato verso un metodo create nel RoomsController, che al momento non esiste; quindi, dobbiamo aggiungerlo.

```ruby
#app/controllers/rooms_controller.rb
def create
  @room = Room.create(name: params["room"]["name"])
end
```

Possiamo aggiungere questo modulo al nostro file index rendendo il suo parziale nel seguente modo:

```ruby
<%= render partial: "layouts/new_room_form" %>

```

Inoltre, possiamo aggiungere alcune classi di Bootstrap per dividere la pagina in una parte per l'elenco di stanze e utenti e l'altra per la chat.

```ruby
<div class="row">
  <div class="col-md-2">
    <h5> Hi <%= @current_user.username %> </h5>
    <h4> Users </h4>
    <div>
      <%= turbo_stream_from "users" %>
      <div id="users">
        <%= render @users %>
      </div>
    </div>
    <h4> Rooms </h4>
    <%= render partial: "layouts/new_room_form" %>
    <div>
      <%= turbo_stream_from "rooms" %>
      <div id="rooms">
        <%= render @rooms %>
      </div>
    </div>
  </div>
  <div class="col-md-10 bg-dark">
    The chat box stays here
  </div>
</div>
```

Ora, creando nuove stanze, vediamo che queste stanze vengono create e la pagina viene aggiornata in tempo reale. Probabilmente hai anche notato che il modulo non viene cancellato dopo ogni invio; affronteremo questo problema in seguito utilizzando Stimulus.

### Chat di gruppo

Per le chat di gruppo, dobbiamo essere in grado di instradare verso singole stanze ma rimanere sulla stessa pagina. Facciamo questo aggiungendo tutte le variabili richieste dalla pagina index al metodo show del nostro RoomsController e rendendo comunque la pagina index.

```ruby
#app/controllers/rooms_controller.rb
def show
  @current_user = current_user
  @single_room = Room.find(params[:id])
  @rooms = Room.public_rooms
  @users = User.all_except(@current_user)
  @room = Room.new

  render "index"
end
```

È stata aggiunta una variabile aggiuntiva chiamata @single_room al metodo show. Questa ci fornisce la stanza specifica a cui stiamo navigando; quindi, possiamo aggiungere una dichiarazione condizionale alla nostra pagina index che mostra il nome della stanza a cui abbiamo navigato quando viene cliccato un nome di stanza. Ciò è aggiunto all'interno del div con la classe col-md-10, come mostrato di seguito.

```ruby
<div class="col-md-10 bg-dark text-light">
  <% if @single_room %>
    <h4 class="text-center"> <%= @single_room.name %> </h4>
  <% end %>
</div>
```

Ora passeremo a qualcosa di più interessante, le messaggistiche. Dobbiamo dare alla nostra sezione di chat un'altezza di 100vh in modo che riempia la pagina e includere al suo interno una casella di chat per la creazione dei messaggi. La casella di chat richiederà un modello di messaggio. Questo modello avrà un riferimento all'utente e un riferimento alla stanza, poiché un messaggio non può esistere senza un creatore e la stanza a cui è destinato.


```ruby
rails g model Message user:references room:references content:text
rails db:migrate
```

Abbiamo anche bisogno di identificare questa associazione nei modelli di utente e stanza aggiungendo la seguente riga a ciascuno di essi.

```ruby 
has_many :messages
```

Aggiungiamo un modulo alla nostra pagina per la creazione di messaggi e aggiungiamogli uno stile:

```ruby
#app/views/layouts/_new_message_form.html.erb
<div class="form-group msg-form">
  <%= form_with(model: [@single_room ,@message], remote: true, class: "d-flex" ) do |f| %>
    <%= f.text_field :content, id: 'chat-text', class: "form-control msg-content", autocomplete: 'off' %>
    <%= f.submit data: { disable_with: false }, class: "btn btn-primary" %>
  <% end %>
</div>
```

```ruby
#app/assets/stylesheets/rooms.scss
  .msg-form {
    position: fixed;
    bottom: 0;
    width: 90%
  }

  .col-md-10 {
    height: 100vh;
    overflow: scroll;
  }

  .msg-content {
    width: 80%;
    margin-right: 5px;
  }
```

Questo modulo include una variabile @message; quindi, dobbiamo definirla nel nostro controller. La aggiungiamo al metodo show del nostro RoomsController.

```ruby
@message = Message.new
```

Nel nostro file routes.rb, aggiungiamo la risorsa del messaggio all'interno della risorsa della stanza, poiché questo allega ai parametri l'id della stanza da cui viene creato il messaggio.

```ruby
resources :rooms do
  resources :messages
end
```

Ogni volta che viene creato un nuovo messaggio, vogliamo che venga trasmesso nella stanza in cui è stato creato. Per fare ciò, abbiamo bisogno di un parziale del messaggio che renderà il messaggio. Poiché questo è ciò che verrà trasmesso, abbiamo anche bisogno di uno turbo_stream che riceva il messaggio trasmesso per quella particolare stanza e un div che fungerà da contenitore per l'aggiunta di questi messaggi. Non dimentichiamo che l'id di questo contenitore deve essere lo stesso del target della trasmissione.

Aggiungiamo questo al nostro modello di messaggio:

```ruby
#app/models/message.rb
after_create_commit { broadcast_append_to self.room }
```

In questo modo, trasmette alla stanza specifica in cui è stato creato.

Aggiungiamo anche lo stream, il contenitore dei messaggi e il modulo dei messaggi al nostro file index:

```ruby
#within the @single_room condition in app/views/rooms/index.html.erb
<%= turbo_stream_from @single_room %>
<div id="messages">
</div>
<%= render partial: 'layouts/new_message_form' >
```

Creiamo il parziale del messaggio che verrà trasmesso, e al suo interno mostriamo solo il nome utente del mittente se la stanza è pubblica.

```ruby
#app/views/messages/_message.html.erb
<div>
  <% unless message.room.is_private %>
    <h6 class="name"> <%= message.user.username %> </h6>
  <% end %>
  <%= message.content %>
</div>
```

Dalla console, se creiamo un messaggio, possiamo vedere che viene trasmesso alla sua stanza utilizzando il modello assegnato.

```ruby
 Message.create(user_id: 1, room_id:1, content: "Ciao")
  TRANSACTION (0.1ms)  begin transaction
  User Load (0.2ms)  SELECT "users".* FROM "users" WHERE "users"."id" = ? LIMIT ?  [["id", 1], ["LIMIT", 1]]
  Room Load (0.1ms)  SELECT "rooms".* FROM "rooms" WHERE "rooms"."id" = ? LIMIT ?  [["id", 1], ["LIMIT", 1]]
  Message Create (0.5ms)  INSERT INTO "messages" ("user_id", "room_id", "content", "created_at", "updated_at") VALUES (?, ?, ?, ?, ?)  [["user_id", 1], ["room_id", 1], ["content", "Ciao"], ["created_at", "2023-12-20 04:46:31.186598"], ["updated_at", "2023-12-20 04:46:31.186598"]]
  TRANSACTION (2.6ms)  commit transaction
  Rendered messages/_message.html.erb (Duration: 2.8ms | Allocations: 276)
[ActionCable] Broadcasting to Z2lkOi8vY2hhdGFwcC9Sb29tLzE: "<turbo-stream action=\"append\" target=\"messages\"><template><div class=\"cont-1\">\n  <div class=\"message-box msg-1 \" >\n      <h6 class=\"name\"> Antonino </h6>\n  Ciao\n  </div>\n</div>  </template></turbo-stream>"
=>
```

Per abilitare la creazione di messaggi dalla dashboard, dobbiamo aggiungere il metodo create al controller dei messaggi (MessagesController).

```ruby
#app/controllers/messages_controller.rb
class MessagesController < ApplicationController
  def create
    @current_user = current_user
    @message = @current_user.messages.create(content: msg_params[:content], room_id: params[:room_id])
  end

  private

  def msg_params
    params.require(:message).permit(:content)
  end
end
```

Questa è la situazione che otteniamo:

Inseriere immagine:


Come possiamo vedere nel video sopra, i messaggi vengono aggiunti, ma se ci spostiamo in un'altra stanza, sembra che perdiamo i messaggi nella precedente quando torniamo. Ciò avviene perché non stiamo recuperando i messaggi che appartengono a una stanza per la visualizzazione. Per fare ciò, nel metodo show del controller delle stanze (RoomsController), aggiungiamo una variabile che recupera tutti i messaggi appartenenti a una stanza, e sulla pagina index, renderizziamo i messaggi recuperati. Possiamo anche notare che il modulo dei messaggi non viene cancellato dopo l'invio di un messaggio; questo sarà gestito con Stimulus in seguito.

```ruby
#in the show method of app/controllers/rooms_controller.rb
@messages = @single_room.messages
#within the div with id of 'messages'
  <%= render @messages %>
```

Ora, ogni stanza avrà i suoi messaggi caricati all'ingresso.

Dobbiamo rendere questo aspetto più gradevole allineando i messaggi dell'utente corrente a destra e gli altri a sinistra. Il modo più diretto per farlo sarebbe assegnare classi in base alla condizione message.user == current_user, ma le variabili locali non sono disponibili per gli stream; pertanto, per un messaggio trasmesso, non ci sarebbe alcun current_user. Cosa possiamo fare? Possiamo assegnare una classe al contenitore del messaggio in base all'id del mittente del messaggio e poi sfruttare il metodo di aiuto current_user per aggiungere uno stile al nostro file application.html.erb. In questo modo, se l'id dell'utente corrente è 2, la classe nel tag di stile in application.html.erb sarà .msg-2, che corrisponderà anche alla classe nel nostro parziale di messaggio quando il mittente del messaggio è l'utente corrente.

```ruby
#app/views/messages/_message.html.erb
<div class="cont-<%= message.user.id %>">
  <div class="message-box msg-<%= message.user.id %> " >
    <% unless message.room.is_private %>
      <h6 class="name"> <%= message.user.username %> </h6>
    <% end %>
  <%= message.content %>
  </div>
</div>
```
Aggiungiamo lo stile per il message-box:

```ruby
#app/assets/stylesheets/rooms.scss
.message-box {
  width: fit-content;
  max-width: 40%;
  padding: 5px;
  border-radius: 10px;
  margin-bottom: 10px;
  background-color: #555555 ;
  padding: 10px
}
```

Nel tag head del nostro file application.html.erb.

```ruby
#app/views/layouts/application.html.erb
<style>
  <%= ".msg-#{current_user&.id}" %> {
  background-color: #007bff !important;
  padding: 10px;
  }
  <%= ".cont-#{current_user&.id}" %> {
  display: flex;
  justify-content: flex-end
  }
</style>
```

Aggiungiamo il tag !important al background-color perché vogliamo che il colore di sfondo venga sovrascritto per l'utente corrente.

Le nostre chat avranno quindi questo aspetto:

Inserire immagine