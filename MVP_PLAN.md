# MountainRide – Plan MVP Simplificado

## Objetivo
Lanzar la versión más simple posible que permita publicar y descubrir viajes a centros de ski, con contacto vía WhatsApp. Mobile-first, rápido de implementar, fácil de iterar.

## Principios MVP
- **Simplicidad primero**: Si hay duda entre implementar algo complejo o simple, elegir simple
- **Rails conventions over custom logic**: Usar lo que Rails ofrece nativamente
- **No premature optimization**: Caché, service objects, etc. solo si se necesitan
- **Ship fast, iterate faster**: Mejor lanzar con menos features y agregar basado en feedback real

---

## Alcance MVP (Lo mínimo para lanzar)

### ✅ Debe tener (Core)
- Registro e inicio de sesión de usuarios (Devise)
- Crear viaje (usuario autenticado, campos: destino, fecha/hora, precio, cupos, descripción, teléfono)
- Listar viajes próximos (públicos, sin autenticación requerida para ver)
- Filtro simple por destino (dropdown)
- Contactar por WhatsApp (link directo)
- Responsive mobile-first (Tailwind)
- Admin para moderar (ActiveAdmin existente)

### 🚫 NO incluir en MVP (Post-launch)
- ❌ Calendario visual custom (usar `input[type="date"]` nativo)
- ❌ Filtro por fecha (mostrar próximos 7 días por defecto)
- ❌ Turbo Frames/Stimulus controllers (YAGNI para MVP)
- ❌ Pundit/ActionPolicy (simple ownership check)
- ❌ Service objects (callbacks de ActiveRecord suficientes)
- ❌ Teléfono predeterminado con checkbox (simplificar: siempre guardar último usado)
- ❌ Vista detalle de viaje (todo en card de listado)
- ❌ Compartir viaje (social share)
- ❌ Rack::Attack (agregar si hay problemas de spam)

---

## Fase 1: Fundación (Día 1-2)

### 1.1 Setup inicial
- [x] Verificar Gemfile tiene: devise, tailwindcss-rails, pundit
- [x] Generar configuración Devise: `rails generate devise:install`
- [x] Generar vistas Devise: `rails generate devise:views`
- [ ] Configurar locale a español (`config.i18n.default_locale = :es`)
- [ ] Configurar zona horaria Chile: `config.time_zone = 'America/Santiago'`

### 1.2 Modelo User ✅
```bash
rails generate devise User first_name:string last_name:string phone:string
rails db:migrate
```

**Validaciones en User:**
- [x] `validates :first_name, :last_name, presence: true`
- [x] `validates :phone, format: { with: /\A569\d{8}\z/ }, presence: true`
- [x] Helper: `def full_name; "#{first_name} #{last_name}"; end`
- [x] Asociación: `has_many :trips, dependent: :destroy`
- [x] Factory: FactoryBot con datos realistas
- [x] Specs: 5/6 passing (1 pending Trip)

### 1.3 Modelo SkiCenter ✅
```bash
rails generate model SkiCenter name:string slug:string description:text address:string latitude:decimal longitude:decimal website_url:string position:integer active:boolean
rails db:migrate
```

**Validaciones:**
- [x] `validates :name, :slug, presence: true`
- [x] `validates :slug, uniqueness: true, format: { with: /\A[a-z0-9-]+\z/ }`
- [x] `validates :latitude, :longitude, numericality: true, allow_nil: true`

**Scopes:**
- [x] `scope :active, -> { where(active: true) }`
- [x] `scope :ordered, -> { order(:position, :name) }`

**Callbacks:**
- [x] Auto-generate slug from name
```ruby
before_validation :generate_slug, if: -> { slug.blank? }

private

def generate_slug
  self.slug = name.parameterize if name.present?
end
```

**Índices:**
- [x] `add_index :ski_centers, :slug, unique: true`
- [x] `add_index :ski_centers, :active`
- [x] `add_index :ski_centers, :position`
- [x] Factory: FactoryBot con datos de centros chilenos
- [x] Specs: 10/11 passing (1 pending Trip)

### 1.4 Modelo Trip
```bash
rails generate model Trip user:references ski_center:references departure_at:datetime price:integer seats:integer description:text custom_contact_phone:string status:integer
rails db:migrate
```

**Enum:**
```ruby
enum :status, {
  published: 0,
  full: 1,
  cancelled: 2
}
```

**Validaciones:**
- `validates :ski_center, :departure_at, :price, :seats, presence: true`
- `validates :seats, numericality: { greater_than: 0 }`
- `validates :price, numericality: { greater_than_or_equal_to: 0 }`
- `validates :custom_contact_phone, format: { with: /\A569\d{8}\z/ }, allow_blank: true`
- `validate :departure_must_be_future`

**Asociaciones:**
- `belongs_to :user`
- `belongs_to :ski_center`
- `delegate :name, to: :ski_center, prefix: true`

**Scopes:**
- `scope :upcoming, -> { where('departure_at > ?', Time.current).order(:departure_at) }`
- `scope :published, -> { where(status: :published) }`
- `scope :by_ski_center, ->(center_id) { where(ski_center_id: center_id) if center_id.present? }`

**Método para teléfono:**
```ruby
# Usa teléfono custom si existe, sino el del usuario
def contact_phone
  custom_contact_phone.presence || user.phone
end

def whatsapp_phone
  contact_phone
end
```

**Índices:**
```ruby
add_index :trips, :ski_center_id
add_index :trips, :departure_at
add_index :trips, [:ski_center_id, :departure_at]
add_index :trips, :status
```

---

## Fase 2: CRUD Básico (Día 3-4)

### 2.1 Rutas
```ruby
Rails.application.routes.draw do
  devise_for :users
  devise_for :admin_users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)

  resource :profile, only: [:edit, :update]

  resources :trips, only: [:index, :new, :create, :edit, :update, :destroy] do
    member do
      patch :mark_full
      patch :cancel
    end
  end

  root "trips#index"
end
```

### 2.2 Controller
```ruby
class TripsController < ApplicationController
  before_action :authenticate_user!, except: [:index]
  before_action :set_trip, only: [:edit, :update, :destroy, :mark_full, :cancel]
  before_action :authorize_trip!, only: [:edit, :update, :destroy, :mark_full, :cancel]

  def index
    @ski_centers = SkiCenter.active.ordered
    @trips = Trip.published.upcoming.includes(:user, :ski_center)
    @trips = @trips.by_ski_center(params[:ski_center_id])
    @trips = @trips.limit(20) # Prevenir cargar demasiados
  end

  def new
    @ski_centers = SkiCenter.active.ordered
    @trip = current_user.trips.build
  end

  def create
    @trip = current_user.trips.build(trip_params)
    if @trip.save
      redirect_to trips_path, notice: 'Viaje publicado exitosamente'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @trip.update(trip_params)
      redirect_to trips_path, notice: 'Viaje actualizado'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @trip.destroy
    redirect_to trips_path, notice: 'Viaje eliminado'
  end

  def mark_full
    @trip.update(status: :full)
    redirect_to trips_path, notice: 'Viaje marcado como completo'
  end

  def cancel
    @trip.update(status: :cancelled)
    redirect_to trips_path, notice: 'Viaje cancelado'
  end

  private

  def set_trip
    @trip = Trip.find(params[:id])
  end

  def authorize_trip!
    redirect_to root_path, alert: 'No autorizado' unless @trip.user == current_user
  end

  def trip_params
    params.require(:trip).permit(:ski_center_id, :departure_at, :price, :seats, :description, :custom_contact_phone)
  end
end
```

### 2.3 ProfilesController (nuevo)
```ruby
# app/controllers/profiles_controller.rb
class ProfilesController < ApplicationController
  before_action :authenticate_user!

  def edit
    @user = current_user
  end

  def update
    @user = current_user
    if @user.update(user_params)
      redirect_to root_path, notice: 'Perfil actualizado. Tus nuevos viajes usarán este teléfono.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:first_name, :last_name, :phone)
  end
end
```

---

## Fase 3: Vistas Mobile-First (Día 5-6)

### 3.1 Layout principal (`app/views/layouts/application.html.erb`)
```erb
<!DOCTYPE html>
<html>
  <head>
    <title>MountainRide</title>
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <%= csrf_meta_tags %>
    <%= csp_meta_tag %>
    <%= stylesheet_link_tag "application", "data-turbo-track": "reload" %>
    <%= javascript_importmap_tags %>
  </head>

  <body class="bg-gray-50">
    <nav class="bg-white shadow sticky top-0 z-10">
      <div class="max-w-lg mx-auto px-4 py-3 flex justify-between items-center">
        <%= link_to "⛷️ MountainRide", root_path, class: "text-xl font-bold text-blue-600" %>
        <div class="flex gap-2">
          <% if user_signed_in? %>
            <%= link_to "Crear Viaje", new_trip_path, class: "btn-primary" %>
            <%= link_to "Salir", destroy_user_session_path, data: { turbo_method: :delete }, class: "btn-secondary" %>
          <% else %>
            <%= link_to "Ingresar", new_user_session_path, class: "btn-secondary" %>
            <%= link_to "Registrarse", new_user_registration_path, class: "btn-primary" %>
          <% end %>
        </div>
      </div>
    </nav>

    <main class="max-w-lg mx-auto px-4 py-6">
      <% if notice.present? %>
        <div class="bg-green-100 text-green-800 px-4 py-3 rounded mb-4"><%= notice %></div>
      <% end %>
      <% if alert.present? %>
        <div class="bg-red-100 text-red-800 px-4 py-3 rounded mb-4"><%= alert %></div>
      <% end %>

      <%= yield %>
    </main>
  </body>
</html>
```

### 3.2 Tailwind config (`config/tailwind.config.js`)
```javascript
module.exports = {
  content: [
    './app/views/**/*.html.erb',
    './app/helpers/**/*.rb',
    './app/javascript/**/*.js'
  ],
  theme: {
    extend: {
      colors: {
        'primary': '#2563EB',
        'secondary': '#64748B',
      }
    }
  }
}
```

### 3.3 CSS helpers (`app/assets/stylesheets/application.tailwind.css`)
```css
@tailwind base;
@tailwind components;
@tailwind utilities;

@layer components {
  .btn-primary {
    @apply bg-blue-600 text-white px-4 py-2 rounded-lg font-medium hover:bg-blue-700 transition;
  }

  .btn-secondary {
    @apply bg-gray-200 text-gray-800 px-4 py-2 rounded-lg font-medium hover:bg-gray-300 transition;
  }

  .card {
    @apply bg-white rounded-lg shadow-sm p-4 mb-4;
  }

  .form-input {
    @apply w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent;
  }

  .form-label {
    @apply block text-sm font-medium text-gray-700 mb-1;
  }
}
```

### 3.4 Vista Index (`app/views/trips/index.html.erb`)
```erb
<div class="mb-6">
  <h1 class="text-2xl font-bold mb-4">Próximos Viajes</h1>

  <%= form_with url: trips_path, method: :get, class: "mb-4" do |f| %>
    <%= f.select :ski_center_id,
      options_for_select([["Todos los destinos", ""]] + @ski_centers.map { |sc| [sc.name, sc.id] }, params[:ski_center_id]),
      {},
      class: "form-input",
      onchange: "this.form.requestSubmit()" %>
  <% end %>
</div>

<div class="space-y-4">
  <% if @trips.any? %>
    <% @trips.each do |trip| %>
      <%= render 'trip_card', trip: trip %>
    <% end %>
  <% else %>
    <div class="card text-center text-gray-500">
      No hay viajes disponibles para estos filtros
    </div>
  <% end %>
</div>
```

### 3.5 Partial Trip Card (`app/views/trips/_trip_card.html.erb`)
```erb
<div class="card">
  <div class="flex justify-between items-start mb-3">
    <div>
      <h3 class="text-lg font-bold text-gray-900"><%= trip.ski_center_name %></h3>
      <p class="text-sm text-gray-500"><%= trip.user.full_name %></p>
    </div>
    <div class="text-right">
      <span class="text-xl font-bold text-blue-600">$<%= number_with_delimiter(trip.price) %></span>
      <p class="text-xs text-gray-500"><%= pluralize(trip.seats, 'cupo') %></p>
    </div>
  </div>

  <div class="mb-3">
    <span class="inline-block bg-blue-100 text-blue-800 text-xs px-2 py-1 rounded">
      📅 <%= l(trip.departure_at, format: :short) %>
    </span>
    <% if trip.full? %>
      <span class="inline-block bg-red-100 text-red-800 text-xs px-2 py-1 rounded">Completo</span>
    <% end %>
  </div>

  <p class="text-sm text-gray-700 mb-4"><%= truncate(trip.description, length: 100) %></p>

  <div class="flex gap-2">
    <%= link_to "Contactar vía WhatsApp",
      whatsapp_url(trip),
      target: "_blank",
      class: "btn-primary flex-1 text-center #{'opacity-50 pointer-events-none' if trip.full?}" %>

    <% if user_signed_in? && current_user == trip.user %>
      <%= link_to "Editar", edit_trip_path(trip), class: "btn-secondary" %>
      <% unless trip.full? %>
        <%= button_to "Marcar completo", mark_full_trip_path(trip), method: :patch, class: "btn-secondary" %>
      <% end %>
    <% end %>
  </div>
</div>
```

### 3.6 Helper WhatsApp (`app/helpers/trips_helper.rb`)
```ruby
module TripsHelper
  def whatsapp_url(trip)
    message = "Hola #{trip.user.first_name}, vi tu viaje a #{trip.ski_center_name} " \
              "el #{l(trip.departure_at, format: :short)}. ¿Todavía hay cupos disponibles?"
    "https://wa.me/#{trip.whatsapp_phone}?text=#{CGI.escape(message)}"
  end
end
```

### 3.7 Vista Perfil (`app/views/profiles/edit.html.erb`)
```erb
<div class="max-w-md mx-auto">
  <h1 class="text-2xl font-bold mb-6">Mi Perfil</h1>

  <%= form_with model: @user, url: profile_path, method: :patch, class: "space-y-4" do |f| %>
    <% if @user.errors.any? %>
      <div class="bg-red-100 text-red-800 px-4 py-3 rounded">
        <ul>
          <% @user.errors.full_messages.each do |message| %>
            <li><%= message %></li>
          <% end %>
        </ul>
      </div>
    <% end %>

    <div>
      <%= f.label :first_name, "Nombre", class: "form-label" %>
      <%= f.text_field :first_name, class: "form-input" %>
    </div>

    <div>
      <%= f.label :last_name, "Apellido", class: "form-label" %>
      <%= f.text_field :last_name, class: "form-input" %>
    </div>

    <div>
      <%= f.label :phone, "Teléfono WhatsApp", class: "form-label" %>
      <%= f.text_field :phone, class: "form-input", placeholder: "569XXXXXXXX" %>
      <p class="text-xs text-gray-500 mt-1">
        Este número se usará por defecto en tus nuevos viajes. Formato: 569 + tu número
      </p>
    </div>

    <div class="flex gap-2">
      <%= f.submit "Guardar Cambios", class: "btn-primary flex-1" %>
      <%= link_to "Cancelar", root_path, class: "btn-secondary" %>
    </div>
  <% end %>
</div>
```

### 3.8 Form (`app/views/trips/_form.html.erb`)
```erb
<%= form_with model: trip, class: "space-y-4" do |f| %>
  <% if trip.errors.any? %>
    <div class="bg-red-100 text-red-800 px-4 py-3 rounded">
      <ul>
        <% trip.errors.full_messages.each do |message| %>
          <li><%= message %></li>
        <% end %>
      </ul>
    </div>
  <% end %>

  <div>
    <%= f.label :ski_center_id, "Destino", class: "form-label" %>
    <%= f.collection_select :ski_center_id, @ski_centers, :id, :name, { prompt: "Selecciona un centro de ski" }, class: "form-input" %>
  </div>

  <div>
    <%= f.label :departure_at, "Fecha y hora de salida", class: "form-label" %>
    <%= f.datetime_local_field :departure_at, class: "form-input" %>
  </div>

  <div>
    <%= f.label :price, "Precio (CLP)", class: "form-label" %>
    <%= f.number_field :price, class: "form-input", placeholder: "15000" %>
  </div>

  <div>
    <%= f.label :seats, "Cupos disponibles", class: "form-label" %>
    <%= f.number_field :seats, class: "form-input", min: 1, max: 10 %>
  </div>

  <div>
    <%= f.label :custom_contact_phone, "Teléfono WhatsApp (opcional)", class: "form-label" %>
    <%= f.text_field :custom_contact_phone,
        class: "form-input",
        placeholder: current_user.phone,
        value: f.object.custom_contact_phone || current_user.phone %>
    <p class="text-xs text-gray-500 mt-1">
      Por defecto: <%= current_user.phone %>.
      <%= link_to "Editar en perfil", edit_profile_path, class: "text-blue-600" %>
    </p>
  </div>

  <div>
    <%= f.label :description, "Descripción", class: "form-label" %>
    <%= f.text_area :description, rows: 4, class: "form-input", placeholder: "Salida desde Las Condes, vehículo 4x4..." %>
  </div>

  <div class="flex gap-2">
    <%= f.submit "Publicar Viaje", class: "btn-primary flex-1" %>
    <%= link_to "Cancelar", trips_path, class: "btn-secondary" %>
  </div>
<% end %>
```

---

## Fase 4: Internacionalización (Día 6)

### 4.1 Locale español (`config/locales/es.yml`)
```yaml
es:
  activerecord:
    models:
      trip: "Viaje"
      user: "Usuario"
      ski_center: "Centro de Ski"
    attributes:
      trip:
        ski_center: "Destino"
        departure_at: "Fecha de salida"
        price: "Precio"
        seats: "Cupos"
        description: "Descripción"
        custom_contact_phone: "Teléfono de contacto personalizado"
      ski_center:
        name: "Nombre"
        slug: "Identificador"
        description: "Descripción"
        address: "Dirección"
        website_url: "Sitio web"
        position: "Orden"
        active: "Activo"
    errors:
      models:
        trip:
          attributes:
            departure_at:
              must_be_future: "debe ser en el futuro"
```

---

## Fase 5: Admin (Día 7)

### 5.1 ActiveAdmin SkiCenter
```ruby
# app/admin/ski_centers.rb
ActiveAdmin.register SkiCenter do
  permit_params :name, :slug, :description, :address, :latitude, :longitude,
                :website_url, :position, :active

  index do
    selectable_column
    id_column
    column :name
    column :slug
    column :active
    column :position
    column "Viajes" do |center|
      center.trips.count
    end
    actions
  end

  filter :name
  filter :slug
  filter :active
  filter :created_at

  form do |f|
    f.inputs "Información Básica" do
      f.input :name
      f.input :slug, hint: 'Se genera automáticamente si está vacío'
      f.input :description
      f.input :active
      f.input :position, hint: 'Menor número = aparece primero'
    end

    f.inputs "Ubicación" do
      f.input :address
      f.input :latitude
      f.input :longitude
      f.input :website_url
    end

    f.actions
  end

  show do
    attributes_table do
      row :name
      row :slug
      row :description
      row :address
      row :latitude
      row :longitude
      row :website_url
      row :position
      row :active
      row :created_at
      row :updated_at
    end

    panel "Viajes Recientes" do
      table_for ski_center.trips.order(departure_at: :desc).limit(10) do
        column :id
        column :user
        column :departure_at
        column :price
        column :seats
        column :status
        column "" do |trip|
          link_to "Ver", admin_trip_path(trip)
        end
      end
    end
  end
end
```

### 5.2 ActiveAdmin Trip
```ruby
# app/admin/trips.rb
ActiveAdmin.register Trip do
  permit_params :status

  filter :ski_center
  filter :status
  filter :departure_at
  filter :user
  filter :created_at

  index do
    selectable_column
    id_column
    column :user
    column :ski_center
    column :departure_at
    column :price
    column :seats
    column :status
    actions
  end

  show do
    attributes_table do
      row :user
      row :ski_center
      row :departure_at
      row :price
      row :seats
      row :description
      row "Teléfono de contacto" do |trip|
        trip.contact_phone
      end
      row :custom_contact_phone
      row :status
      row :created_at
      row :updated_at
    end
  end

  form do |f|
    f.inputs do
      f.input :status, as: :select, collection: Trip.statuses.keys
    end
    f.actions
  end
end
```

### 5.3 ActiveAdmin User
```ruby
# app/admin/users.rb
ActiveAdmin.register User do
  permit_params :first_name, :last_name, :phone

  filter :email
  filter :first_name
  filter :last_name
  filter :phone
  filter :created_at

  index do
    selectable_column
    id_column
    column :email
    column :first_name
    column :last_name
    column :phone
    column "Viajes publicados" do |user|
      user.trips.count
    end
    column :created_at
    actions
  end

  show do
    attributes_table do
      row :email
      row :first_name
      row :last_name
      row :phone
      row :created_at
      row :updated_at
      row :sign_in_count
      row :current_sign_in_at
      row :last_sign_in_at
    end

    panel "Viajes" do
      table_for user.trips.order(departure_at: :desc) do
        column :id
        column :ski_center
        column :departure_at
        column :price
        column :seats
        column :status
        column "" do |trip|
          link_to "Ver", admin_trip_path(trip)
        end
      end
    end
  end

  form do |f|
    f.inputs do
      f.input :first_name
      f.input :last_name
      f.input :phone
    end
    f.actions
  end
end
```

### 5.4 ActiveAdmin Dashboard
```ruby
# app/admin/dashboard.rb
ActiveAdmin.register_page "Dashboard" do
  menu priority: 1, label: proc { I18n.t("active_admin.dashboard") }

  content title: proc { I18n.t("active_admin.dashboard") } do
    columns do
      column do
        panel "Estadísticas Generales" do
          para "Usuarios registrados: #{User.count}"
          para "Viajes publicados: #{Trip.published.count}"
          para "Viajes próximos: #{Trip.upcoming.count}"
          para "Centros de ski activos: #{SkiCenter.active.count}"
        end
      end

      column do
        panel "Esta Semana" do
          para "Nuevos usuarios: #{User.where('created_at > ?', 1.week.ago).count}"
          para "Nuevos viajes: #{Trip.where('created_at > ?', 1.week.ago).count}"
        end
      end
    end

    columns do
      column do
        panel "Viajes Recientes" do
          table_for Trip.order(created_at: :desc).limit(10) do
            column :id
            column :user
            column :ski_center
            column :departure_at
            column :status
            column "" do |trip|
              link_to "Ver", admin_trip_path(trip)
            end
          end
        end
      end

      column do
        panel "Centros Más Populares" do
          table_for SkiCenter.joins(:trips)
                              .group('ski_centers.id')
                              .order('COUNT(trips.id) DESC')
                              .limit(5)
                              .select('ski_centers.*, COUNT(trips.id) as trips_count') do
            column :name
            column "Viajes" do |center|
              center.trips_count
            end
          end
        end
      end
    end
  end
end
```

---

## Fase 6: Testing (Día 8-9)

### 6.1 Factories
```ruby
# spec/factories/users.rb
FactoryBot.define do
  factory :user do
    first_name { "Juan" }
    last_name { "Pérez" }
    sequence(:email) { |n| "user#{n}@example.com" }
    phone { "56987654321" }
    password { "password123" }
    password_confirmation { "password123" }
  end
end

# spec/factories/ski_centers.rb
FactoryBot.define do
  factory :ski_center do
    sequence(:name) { |n| "Centro Ski #{n}" }
    sequence(:slug) { |n| "centro-ski-#{n}" }
    description { "Un centro de ski de prueba" }
    address { "Camino a la montaña" }
    position { 1 }
    active { true }
  end
end

# spec/factories/trips.rb
FactoryBot.define do
  factory :trip do
    user
    ski_center
    departure_at { 3.days.from_now }
    price { 15000 }
    seats { 3 }
    description { "Viaje de prueba" }
    status { :published }
  end
end
```

### 6.2 Model specs
```ruby
# spec/models/ski_center_spec.rb
require 'rails_helper'

RSpec.describe SkiCenter, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:slug) }
    it { should validate_uniqueness_of(:slug) }
  end

  describe 'associations' do
    it { should have_many(:trips).dependent(:restrict_with_error) }
  end

  describe 'scopes' do
    it 'returns only active centers' do
      active = create(:ski_center, active: true)
      inactive = create(:ski_center, active: false)
      expect(SkiCenter.active).to include(active)
      expect(SkiCenter.active).not_to include(inactive)
    end
  end

  describe 'callbacks' do
    it 'generates slug from name if blank' do
      center = create(:ski_center, name: 'Valle Nevado', slug: nil)
      expect(center.slug).to eq('valle-nevado')
    end
  end
end

# spec/models/trip_spec.rb
require 'rails_helper'

RSpec.describe Trip, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:ski_center) }
    it { should validate_presence_of(:departure_at) }
    it { should validate_presence_of(:price) }
    it { should validate_presence_of(:seats) }
    it { should validate_numericality_of(:seats).is_greater_than(0) }

    it 'validates departure is in future' do
      trip = build(:trip, departure_at: 1.day.ago)
      expect(trip).not_to be_valid
    end
  end

  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:ski_center) }
  end

  describe 'scopes' do
    it 'returns only upcoming trips' do
      past = create(:trip, departure_at: 1.day.ago)
      future = create(:trip, departure_at: 1.day.from_now)
      expect(Trip.upcoming).to include(future)
      expect(Trip.upcoming).not_to include(past)
    end

    it 'filters by ski_center' do
      valle = create(:ski_center, name: 'Valle Nevado')
      parva = create(:ski_center, name: 'La Parva')
      trip_valle = create(:trip, ski_center: valle)
      trip_parva = create(:trip, ski_center: parva)

      expect(Trip.by_ski_center(valle.id)).to include(trip_valle)
      expect(Trip.by_ski_center(valle.id)).not_to include(trip_parva)
    end
  end

  describe '#contact_phone' do
    let(:user) { create(:user, phone: '56987654321') }

    it 'returns custom_contact_phone if present' do
      trip = create(:trip, user: user, custom_contact_phone: '56912345678')
      expect(trip.contact_phone).to eq('56912345678')
    end

    it 'returns user phone if custom_contact_phone is blank' do
      trip = create(:trip, user: user, custom_contact_phone: nil)
      expect(trip.contact_phone).to eq('56987654321')
    end
  end
end

# spec/models/user_spec.rb
require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:first_name) }
    it { should validate_presence_of(:last_name) }
    it { should validate_presence_of(:phone) }

    it 'validates phone format' do
      user = build(:user, phone: '123456')
      expect(user).not_to be_valid
      expect(user.errors[:phone]).to be_present
    end
  end

  describe 'associations' do
    it { should have_many(:trips).dependent(:destroy) }
  end

  describe '#full_name' do
    it 'returns first_name and last_name' do
      user = build(:user, first_name: 'Juan', last_name: 'Pérez')
      expect(user.full_name).to eq('Juan Pérez')
    end
  end
end
```

### 6.3 Request specs
```ruby
# spec/requests/trips_spec.rb
require 'rails_helper'

RSpec.describe 'Trips', type: :request do
  describe 'GET /trips' do
    it 'returns success' do
      get trips_path
      expect(response).to have_http_status(:success)
    end

    it 'filters by ski_center' do
      valle = create(:ski_center, name: 'Valle Nevado')
      parva = create(:ski_center, name: 'La Parva')
      create(:trip, ski_center: valle)
      create(:trip, ski_center: parva)

      get trips_path, params: { ski_center_id: valle.id }
      expect(response.body).to include('Valle Nevado')
      expect(response.body).not_to include('La Parva')
    end
  end

  describe 'POST /trips' do
    let(:ski_center) { create(:ski_center) }

    context 'when authenticated' do
      let(:user) { create(:user) }
      before { sign_in user }

      it 'creates trip' do
        expect {
          post trips_path, params: {
            trip: {
              ski_center_id: ski_center.id,
              departure_at: 3.days.from_now,
              price: 15000,
              seats: 3,
              description: 'Test trip'
            }
          }
        }.to change(Trip, :count).by(1)
      end
    end

    context 'when not authenticated' do
      it 'redirects to login' do
        post trips_path, params: { trip: attributes_for(:trip) }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'PATCH /trips/:id' do
    let(:user) { create(:user) }
    let(:trip) { create(:trip, user: user) }

    context 'when owner' do
      before { sign_in user }

      it 'updates trip' do
        patch trip_path(trip), params: { trip: { seats: 5 } }
        expect(trip.reload.seats).to eq(5)
      end
    end

    context 'when not owner' do
      let(:other_user) { create(:user) }
      before { sign_in other_user }

      it 'does not allow update' do
        patch trip_path(trip), params: { trip: { seats: 5 } }
        expect(response).to redirect_to(root_path)
      end
    end
  end
end

# spec/requests/profiles_spec.rb
require 'rails_helper'

RSpec.describe 'Profiles', type: :request do
  describe 'PATCH /profile' do
    let(:user) { create(:user, phone: '56987654321') }
    before { sign_in user }

    it 'updates user profile' do
      patch profile_path, params: {
        user: {
          first_name: 'Carlos',
          phone: '56912345678'
        }
      }

      user.reload
      expect(user.first_name).to eq('Carlos')
      expect(user.phone).to eq('56912345678')
    end
  end
end
```

---

## Fase 7: Deploy (Día 10)

### 7.1 Variables de entorno
```bash
# .env.example
RAILS_MASTER_KEY=
DATABASE_URL=
DEVISE_SECRET_KEY=
```

### 7.2 Production config
```ruby
# config/environments/production.rb
config.force_ssl = true
config.action_mailer.default_url_options = { host: 'mountainride.cl' }
```

### 7.3 Seeds
```ruby
# db/seeds.rb

# Admin user
AdminUser.find_or_create_by!(email: ENV['ADMIN_EMAIL'] || 'admin@mountainride.cl') do |admin|
  admin.password = ENV['ADMIN_PASSWORD'] || 'changeme123'
  admin.password_confirmation = ENV['ADMIN_PASSWORD'] || 'changeme123'
end

# Centros de ski
ski_centers_data = [
  {
    name: 'Valle Nevado',
    slug: 'valle-nevado',
    description: 'El centro de ski más grande de Sudamérica',
    address: 'Camino a Farellones Km 60, Lo Barnechea',
    latitude: -33.3531,
    longitude: -70.2539,
    website_url: 'https://vallenevado.com',
    position: 1,
    active: true
  },
  {
    name: 'La Parva',
    slug: 'la-parva',
    description: 'Centro de ski familiar con excelente nieve',
    address: 'Camino La Parva s/n, Lo Barnechea',
    latitude: -33.3500,
    longitude: -70.2833,
    website_url: 'https://laparva.cl',
    position: 2,
    active: true
  },
  {
    name: 'El Colorado',
    slug: 'el-colorado',
    description: 'Ski y snowboard para todos los niveles',
    address: 'Camino a Farellones Km 32, Lo Barnechea',
    latitude: -33.3422,
    longitude: -70.2947,
    website_url: 'https://elcolorado.cl',
    position: 3,
    active: true
  },
  {
    name: 'Farellones',
    slug: 'farellones',
    description: 'Pueblo cordillerano y centro de actividades',
    address: 'Camino a Farellones, Lo Barnechea',
    latitude: -33.3575,
    longitude: -70.3042,
    website_url: 'https://farellones.cl',
    position: 4,
    active: true
  },
  {
    name: 'Lagunillas',
    slug: 'lagunillas',
    description: 'Centro de ski en el Cajón del Maipo',
    address: 'Cajón del Maipo, San José de Maipo',
    latitude: -33.7333,
    longitude: -70.0167,
    website_url: nil,
    position: 5,
    active: true
  }
]

ski_centers_data.each do |data|
  SkiCenter.find_or_create_by!(slug: data[:slug]) do |center|
    center.assign_attributes(data)
  end
end

# Usuario de prueba
user = User.find_or_create_by!(email: 'demo@mountainride.cl') do |u|
  u.password = 'password123'
  u.password_confirmation = 'password123'
  u.first_name = 'Juan'
  u.last_name = 'Pérez'
  u.phone = '56987654321'
end

# Viajes de ejemplo
valle_nevado = SkiCenter.find_by(slug: 'valle-nevado')
la_parva = SkiCenter.find_by(slug: 'la-parva')
el_colorado = SkiCenter.find_by(slug: 'el-colorado')

[
  {
    user: user,
    ski_center: valle_nevado,
    departure_at: 3.days.from_now.change(hour: 7, min: 0),
    price: 15000,
    seats: 3,
    description: 'Salida desde Las Condes, vehículo 4x4 equipado. Retorno aproximado a las 17:00.',
    status: :published
  },
  {
    user: user,
    ski_center: la_parva,
    departure_at: 5.days.from_now.change(hour: 8, min: 0),
    price: 12000,
    seats: 2,
    description: 'Retorno flexible según condiciones. Puedo ayudar con equipos.',
    status: :published
  },
  {
    user: user,
    ski_center: el_colorado,
    departure_at: 7.days.from_now.change(hour: 6, min: 30),
    price: 10000,
    seats: 4,
    description: 'Salida temprana desde Providencia. Van cómoda.',
    status: :published
  }
].each do |trip_data|
  Trip.find_or_create_by!(
    user: trip_data[:user],
    ski_center: trip_data[:ski_center],
    departure_at: trip_data[:departure_at]
  ) do |trip|
    trip.assign_attributes(trip_data.except(:user, :ski_center, :departure_at))
  end
end

puts "✅ Seeds completados"
puts "📊 Centros de ski: #{SkiCenter.count}"
puts "👥 Usuarios: #{User.count}"
puts "🚗 Viajes: #{Trip.count}"
```

---

## Criterios de Aceptación MVP

### Funcionales
- ✅ Usuario puede registrarse con email, nombre y teléfono
- ✅ Usuario autenticado puede crear viaje con todos los campos requeridos
- ✅ Visitante anónimo puede ver listado de viajes próximos
- ✅ Se puede filtrar por destino
- ✅ Click en "Contactar" abre WhatsApp con mensaje prellenado
- ✅ Conductor puede marcar viaje como completo
- ✅ Admin puede moderar/cancelar viajes

### No Funcionales
- ✅ Responsive en móvil (320px - 480px)
- ✅ Carga inicial < 3 segundos
- ✅ Formularios validados server-side
- ✅ Tests coverage > 70%

---

## Post-MVP (Backlog Priorizado)

### v1.1 - Mejoras UX (Semana 2)
1. Filtro por fecha (input date nativo)
2. Mis viajes (dashboard simple)
3. Notificación email al publicar viaje
4. Soft delete de viajes (paranoia gem)

### v1.2 - Optimizaciones (Semana 3)
5. Turbo Frames para filtros sin reload
6. Infinite scroll en listado
7. Cache de queries (Russian Doll Caching)
8. Rack::Attack rate limiting

### v1.3 - Social (Semana 4)
9. Compartir viaje (navigator.share API)
10. Sistema de reputación básico
11. Avatar de usuario (Active Storage)
12. Notificaciones push (web push)

### v2.0 - Plataforma (Mes 2)
13. Mensajería interna (ActionCable)
14. Pagos integrados (Transbank/Flow)
15. Sistema de reservas con confirmación
16. API REST para app nativa

---

## Riesgos y Mitigaciones

| Riesgo | Probabilidad | Impacto | Mitigación |
|--------|--------------|---------|------------|
| Spam de viajes falsos | Alta | Alto | Admin manual inicial, luego throttling |
| Teléfonos inválidos | Media | Medio | Validación regex, SMS verification en v1.2 |
| Usuarios no responden WhatsApp | Alta | Bajo | Agregar sistema reputación en v1.3 |
| Sobrecarga de viajes viejos | Media | Medio | Soft delete automático después de departure_at |
| GDPR/Privacidad | Baja | Alto | Consentimiento explícito, opción de ocultar teléfono |

---

## Métricas de Éxito

### Semana 1 post-launch
- 50 usuarios registrados
- 20 viajes publicados
- 100 clicks en "Contactar"

### Mes 1
- 200 usuarios
- 80 viajes
- 10% de usuarios crean viajes
- < 5 reportes de spam

### KPIs Críticos
- **Ratio publicación/contacto**: > 5 contactos por viaje
- **Retorno de conductor**: > 40% publica segundo viaje
- **Tasa de conversión WhatsApp**: (medir en v1.2 con tracking)
