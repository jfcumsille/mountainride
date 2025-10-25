# CLAUDE.md - MountainRide Context

## Proyecto
**MountainRide** es una plataforma web mobile-first para compartir viajes desde Santiago a centros de ski de la Región Metropolitana. Estilo "Uber para la montaña" pero con contacto directo vía WhatsApp (no intermediación).

## Stack Técnico
- **Framework**: Ruby on Rails (edge/main branch)
- **Database**: PostgreSQL
- **Frontend**: Hotwire (Turbo + Stimulus) + TailwindCSS
- **Auth**: Devise
- **Authorization**: Simple ownership checks (no Pundit en MVP)
- **Admin**: ActiveAdmin
- **Testing**: RSpec + FactoryBot + Shoulda Matchers
- **Deploy**: Dockerfile incluido, target Render/Fly/Heroku

## Convenciones del Proyecto

### Nombres y Nomenclatura
- **Modelos**: Singular, PascalCase (`User`, `Trip`)
- **Controllers**: Plural, snake_case (`trips_controller.rb`)
- **Vistas**: snake_case en carpetas plurales (`trips/index.html.erb`)
- **Specs**: Reflejan estructura de app (`spec/models/trip_spec.rb`)

### Principios de Diseño
1. **Mobile-first obligatorio**: Max-width 480px, touch targets > 44px
2. **Rails conventions over configuration**: Usar lo que Rails ofrece por defecto
3. **Simplicidad sobre abstracción**: No service objects, no custom gems si Rails lo tiene
4. **Ship fast, iterate**: Mejor algo funcionando simple que algo complejo sin terminar

### Patrones a SEGUIR
✅ **Callbacks de ActiveRecord**: Para lógica simple (ej: copiar teléfono del usuario)
✅ **Scopes**: Para queries reutilizables (`upcoming`, `by_destination`)
✅ **Helpers**: Para lógica de presentación (ej: `whatsapp_url`)
✅ **Partials**: Para componentes reutilizables (`_trip_card.html.erb`)
✅ **I18n**: Todo texto en español via locale files
✅ **Validaciones server-side**: Nunca confiar en frontend
✅ **Tailwind utilities**: Preferir clases utilitarias sobre custom CSS

### Patrones a EVITAR (en MVP)
❌ **Service Objects**: YAGNI para operaciones simples
❌ **Concerns prematuros**: Solo si se repite en 3+ modelos
❌ **Form Objects**: `accepts_nested_attributes_for` es suficiente
❌ **Presenters/Decorators**: Helpers son más simples
❌ **Turbo Frames sin necesidad**: Solo agregar si hay problema de performance
❌ **JavaScript custom**: HTML nativo primero (ej: `<input type="date">`)

## Estructura de Archivos

```
app/
├── models/
│   ├── user.rb              # Devise user + phone validation
│   ├── trip.rb              # Core model con belongs_to ski_center
│   ├── ski_center.rb        # Centros de ski (Valle Nevado, La Parva, etc.)
│   └── admin_user.rb        # ActiveAdmin
├── controllers/
│   ├── trips_controller.rb  # Main CRUD + mark_full/cancel
│   ├── profiles_controller.rb  # User profile edit
│   └── application_controller.rb
├── views/
│   ├── layouts/
│   │   └── application.html.erb  # Nav + flash messages
│   ├── trips/
│   │   ├── index.html.erb        # Listado con filtros
│   │   ├── new.html.erb
│   │   ├── edit.html.erb
│   │   ├── _form.html.erb
│   │   └── _trip_card.html.erb   # Reusable card component
│   ├── profiles/
│   │   └── edit.html.erb         # User profile edit
│   └── devise/
│       └── (generated views)
├── helpers/
│   └── trips_helper.rb      # whatsapp_url, etc.
├── admin/
│   ├── dashboard.rb         # Stats y métricas
│   ├── ski_centers.rb       # CRUD centros de ski
│   ├── trips.rb             # Moderar viajes
│   └── users.rb             # Gestionar usuarios
└── assets/
    └── stylesheets/
        └── application.tailwind.css  # Tailwind + custom components

config/
├── routes.rb
├── locales/
│   └── es.yml               # Spanish translations
└── tailwind.config.js

spec/
├── models/
│   ├── user_spec.rb
│   ├── trip_spec.rb
│   └── ski_center_spec.rb
├── requests/
│   ├── trips_spec.rb
│   └── profiles_spec.rb
└── factories/
    ├── users.rb
    ├── trips.rb
    └── ski_centers.rb
```

## Modelos Core

### User (Devise)
```ruby
# Atributos custom
first_name :string
last_name :string
phone :string  # Formato: 569XXXXXXXX (usado por defecto en nuevos viajes)

# Validaciones
validates :first_name, :last_name, presence: true
validates :phone, format: { with: /\A569\d{8}\z/ }, presence: true

# Asociaciones
has_many :trips, dependent: :destroy

# Métodos
def full_name
  "#{first_name} #{last_name}"
end
```

### SkiCenter
```ruby
# Atributos
name :string              # Valle Nevado, La Parva, etc.
slug :string              # valle-nevado (auto-generado)
description :text
address :string
latitude :decimal
longitude :decimal
website_url :string
position :integer         # Para ordenamiento (menor = primero)
active :boolean           # Activar/desactivar temporalmente

# Validaciones
validates :name, :slug, presence: true
validates :slug, uniqueness: true, format: { with: /\A[a-z0-9-]+\z/ }

# Asociaciones
has_many :trips, dependent: :restrict_with_error

# Scopes
scope :active, -> { where(active: true) }
scope :ordered, -> { order(:position, :name) }

# Callbacks
before_validation :generate_slug, if: -> { slug.blank? }
```

### Trip
```ruby
# Atributos
user_id :integer
ski_center_id :integer    # Relación en vez de enum
departure_at :datetime
price :integer            # Pesos chilenos
seats :integer
description :text
custom_contact_phone :string  # Opcional, override del user.phone
status :integer           # enum: published, full, cancelled

# Validaciones
validates :ski_center, :departure_at, :price, :seats, presence: true
validates :seats, numericality: { greater_than: 0 }
validates :custom_contact_phone, format: { with: /\A569\d{8}\z/ }, allow_blank: true
validate :departure_must_be_future

# Asociaciones
belongs_to :user
belongs_to :ski_center
delegate :name, to: :ski_center, prefix: true  # trip.ski_center_name

# Scopes
scope :upcoming, -> { where('departure_at > ?', Time.current).order(:departure_at) }
scope :published, -> { where(status: :published) }
scope :by_ski_center, ->(center_id) { where(ski_center_id: center_id) if center_id.present? }

# Métodos de teléfono
def contact_phone
  custom_contact_phone.presence || user.phone
end

def whatsapp_phone
  contact_phone
end
```

## Centros de Ski (Base de Datos)
Los centros de ski ahora son registros de base de datos (modelo SkiCenter), no enums.

**Centros por defecto** (ver seeds):
1. Valle Nevado
2. La Parva
3. El Colorado
4. Farellones
5. Lagunillas

Admin puede agregar más desde ActiveAdmin sin necesidad de código.

## Rutas Principales

```ruby
root "trips#index"                    # Listado público

# Trips
GET    /trips                         # Index (público, filtrable por ski_center_id)
GET    /trips/new                     # Formulario (auth)
POST   /trips                         # Crear (auth)
GET    /trips/:id/edit                # Editar (auth + owner)
PATCH  /trips/:id                     # Update (auth + owner)
DELETE /trips/:id                     # Destroy (auth + owner)
PATCH  /trips/:id/mark_full           # Marcar completo (auth + owner)
PATCH  /trips/:id/cancel              # Cancelar (auth + owner)

# Profile
GET    /profile/edit                  # Editar perfil usuario
PATCH  /profile                       # Actualizar perfil

# Auth
devise_for :users
devise_for :admin_users, ActiveAdmin::Devise.config

# Admin
/admin                                # Dashboard con stats
/admin/ski_centers                    # CRUD centros de ski
/admin/trips                          # Moderar viajes
/admin/users                          # Gestionar usuarios
```

## Tailwind Components Reutilizables

```css
/* Definidos en application.tailwind.css */
.btn-primary      # Botón azul principal
.btn-secondary    # Botón gris secundario
.card             # Tarjeta blanca con sombra
.form-input       # Input estilizado
.form-label       # Label de formulario
```

## Helpers Importantes

### `whatsapp_url(trip)`
Genera URL de WhatsApp con mensaje prellenado:
```ruby
def whatsapp_url(trip)
  message = "Hola #{trip.user.first_name}, vi tu viaje a #{trip.ski_center_name} " \
            "el #{l(trip.departure_at, format: :short)}. ¿Todavía hay cupos disponibles?"
  "https://wa.me/#{trip.whatsapp_phone}?text=#{CGI.escape(message)}"
end
```

### `l(date, format: :short)`
Formateo de fecha en español (I18n)

## Testing

### Factories (FactoryBot)
```ruby
# spec/factories/users.rb
factory :user do
  first_name { "Juan" }
  last_name { "Pérez" }
  sequence(:email) { |n| "user#{n}@example.com" }
  phone { "56987654321" }
  password { "password123" }
  password_confirmation { "password123" }
end

# spec/factories/ski_centers.rb
factory :ski_center do
  sequence(:name) { |n| "Centro Ski #{n}" }
  sequence(:slug) { |n| "centro-ski-#{n}" }
  description { "Un centro de ski de prueba" }
  address { "Camino a la montaña" }
  position { 1 }
  active { true }
end

# spec/factories/trips.rb
factory :trip do
  user
  ski_center
  departure_at { 3.days.from_now }
  price { 15000 }
  seats { 3 }
  description { "Viaje de prueba" }
  status { :published }
end
```

### Coverage Mínimo
- Models: 90%+ (validaciones, scopes, callbacks)
- Controllers: 80%+ (happy path + auth)
- Requests: 70%+ (endpoints principales)

## Configuración Importante

### Locale y Timezone
```ruby
# config/application.rb
config.i18n.default_locale = :es
config.time_zone = 'America/Santiago'
config.active_record.default_timezone = :local
```

### Devise
```ruby
# config/initializers/devise.rb
config.mailer_sender = 'noreply@mountainride.cl'
config.sign_out_via = :delete
```

### Tailwind Purge
```javascript
// config/tailwind.config.js
content: [
  './app/views/**/*.html.erb',
  './app/helpers/**/*.rb',
  './app/javascript/**/*.js'
]
```

## Variables de Entorno

```bash
RAILS_MASTER_KEY          # Rails credentials
DATABASE_URL              # PostgreSQL connection
DEVISE_SECRET_KEY         # Devise token (opcional, usa credentials)
ADMIN_EMAIL               # Para seeds
ADMIN_PASSWORD            # Para seeds
```

## Comandos Comunes

```bash
# Setup
bin/setup

# Tests
bundle exec rspec
bundle exec rspec spec/models/trip_spec.rb

# Linting
bundle exec rubocop
bundle exec rubocop -A  # Auto-correct

# Dev server
bin/dev  # Puma only (Tailwind watch no funciona en Procfile)

# DB
rails db:migrate
rails db:seed
rails db:reset

# Console
rails c

# Assets (IMPORTANTE: Compilar manualmente cuando cambies estilos)
rails tailwindcss:build  # Compila estilos principales (application.tailwind.css -> builds/tailwind.css)
bundle exec tailwindcss build -i ./app/assets/stylesheets/active_admin.css -o ./app/assets/builds/active_admin.css -c ./config/tailwind.config.js  # Compila estilos de ActiveAdmin

# Si cambias estilos de ActiveAdmin, SIEMPRE ejecuta:
bundle exec tailwindcss build -i ./app/assets/stylesheets/active_admin.css -o ./app/assets/builds/active_admin.css -c ./config/tailwind.config.js

# Para desarrollo activo con auto-rebuild (ejecutar en terminales separadas):
# Terminal 1:
rails s
# Terminal 2:
rails tailwindcss:build && rails tailwindcss:watch
# Terminal 3:
bundle exec tailwindcss build -i ./app/assets/stylesheets/active_admin.css -o ./app/assets/builds/active_admin.css -c ./config/tailwind.config.js --watch
```

## Decisiones de Arquitectura Clave

### ¿Por qué SkiCenter como modelo y no enum?
✅ **Flexibilidad**: Admin puede agregar nuevos centros sin código
✅ **Escalabilidad**: Preparado para features futuras (clima, fotos, horarios)
✅ **Data-driven**: Más fácil reportes y estadísticas
✅ **Localización**: Coordenadas para mapas futuros
❌ Más complejo (1 join extra en queries)
**Decisión**: Los beneficios superan el costo. Usar `includes(:ski_center)` para N+1.

### ¿Por qué teléfono híbrido (user.phone + custom_contact_phone)?
✅ **UX simple**: Usuario no repite teléfono en cada viaje
✅ **Flexibilidad**: Puede usar teléfono diferente si necesita
✅ **Corrección fácil**: Edita una vez en perfil, se refleja en nuevos viajes
❌ Dos fuentes de verdad (potencial confusión)
**Decisión**: La conveniencia para el usuario justifica la complejidad mínima.

### ¿Por qué no Pundit/ActionPolicy en MVP?
✅ **Simplicidad**: Simple `before_action` check es suficiente
✅ **Menos abstracciones**: Código más directo y legible
✅ **Velocidad**: Una dependencia menos
❌ No escalable para permisos complejos
**Decisión**: Agregarlo cuando tengamos roles múltiples (v1.2+).

## Reglas de Oro para Claude

1. **KISS**: Si no es necesario para el MVP, no lo implementes
2. **Mobile-first**: Toda decisión de UI debe pensarse para móvil primero
3. **Rails Way**: Si Rails tiene una forma de hacer algo, usa esa
4. **Test coverage**: Cada feature debe tener specs antes de mergear
5. **No premature optimization**: Profile primero, optimiza después
6. **Security by default**: CSRF, validaciones server-side, sanitización
7. **User Experience > Developer Experience**: Si algo es más complejo para el dev pero mejor para el usuario, hazlo
8. **SkiCenter es modelo**: Siempre usar `belongs_to :ski_center`, no enums
9. **Teléfono desde User**: Por defecto `user.phone`, override con `custom_contact_phone`

## Debugging Tips

### Ver queries SQL
```ruby
# En consoles
ActiveRecord::Base.logger = Logger.new(STDOUT)
```

### Tailwind no aplica estilos
```bash
# Limpiar caché
rails tmp:clear
rails assets:clobber
rails tailwindcss:build
```

### ActiveAdmin sin estilos
ActiveAdmin 4.0 beta usa Tailwind CSS (no SASS). Si los estilos no se ven:
```bash
# 1. Verificar que active_admin.css tenga directivas Tailwind
cat app/assets/stylesheets/active_admin.css
# Debe contener:
# @tailwind base;
# @tailwind components;
# @tailwind utilities;

# 2. Compilar CSS de ActiveAdmin
bundle exec tailwindcss build -i ./app/assets/stylesheets/active_admin.css -o ./app/assets/builds/active_admin.css -c ./config/tailwind.config.js

# 3. Precompilar assets (si es necesario)
rails assets:precompile

# 4. Verificar que el archivo se generó correctamente
ls -lh app/assets/builds/active_admin.css  # Debe ser ~62KB, no bytes

# 5. Reiniciar servidor y hard refresh en navegador (Cmd+Shift+R)
```

### Devise redirect loops
Verificar `authenticate_user!` en `ApplicationController` y overrides

## Próximos Pasos (Post-MVP)

Ver `MVP_PLAN.md` sección "Post-MVP" para backlog priorizado.

No implementar nada de la wishlist sin antes confirmar con el equipo:
- Turbo Frames
- Service Objects
- API REST
- Stimulus controllers custom
- Caching
- Background jobs

---

**Última actualización**: 2025-10-25
**Mantenido por**: Equipo MountainRide
**Versión**: MVP v1.0

## Notas Importantes sobre el Entorno de Desarrollo

### bin/dev y Procfile.dev
- **Procfile.dev simplificado**: Solo corre el web server (Puma)
- **Problema conocido**: El proceso `css_admin` (watch de ActiveAdmin CSS) se sale inmediatamente en Procfile
- **Solución**: Compilar CSS de ActiveAdmin manualmente cuando sea necesario
- **Alternativa**: Para desarrollo activo, usar 3 terminales separadas (ver "Comandos Comunes" arriba)

### Foreman
- Necesita `foreman` gem en Gemfile (grupo :development)
- `bin/dev` usa `bundle exec foreman` (no solo `foreman`)
- Si falla, verificar: `bundle list | grep foreman`
