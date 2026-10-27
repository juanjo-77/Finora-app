# Graph Report - Finora-app  (2026-10-27)

## Corpus Check
- Corpus is ~35,184 words - fits in a single context window. You may not need a graph.

## Summary
- 799 nodes · 1161 edges · 49 communities (40 shown, 9 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS · INFERRED: 5 edges (avg confidence: 0.85)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- Community 0
- Community 1
- Community 2
- Community 3
- Community 4
- Community 5
- Community 6
- Community 7
- Community 8
- Community 9
- Community 10
- Community 11
- Community 12
- Community 13
- Community 14
- Community 15
- Community 16
- Community 17
- Community 18
- Community 19
- Community 20
- Community 21
- Community 22
- Community 23
- Community 24
- Community 25
- Community 26
- Community 27
- Community 28
- Community 29
- Community 30
- Community 31
- Community 32
- Community 33
- Community 34
- Community 35
- Community 36
- Community 37
- Community 38
- Community 39
- Community 40
- Community 42

## God Nodes (most connected - your core abstractions)
1. `AppDbContext` - 21 edges
2. `FinanzasApi.Data` - 14 edges
3. `FinanzasApi.Models` - 14 edges
4. `Deuda` - 13 edges
5. `Movimiento` - 13 edges
6. `FinanzasApi.Migrations` - 11 edges
7. `Usuario` - 11 edges
8. `Inversion` - 10 edges
9. `Meta` - 10 edges
10. `DeudasController` - 9 edges

## Surprising Connections (you probably didn't know these)
- `AppDbContext` --references--> `Deuda`  [EXTRACTED]
  api/Data/AppDbContext.cs → api/Models/Deuda.cs
- `AppDbContext` --references--> `Movimiento`  [EXTRACTED]
  api/Data/AppDbContext.cs → api/Models/Movimiento.cs
- `AppDbContext` --references--> `Usuario`  [EXTRACTED]
  api/Data/AppDbContext.cs → api/Models/Usuario.cs
- `Usuario` --references--> `Movimiento`  [EXTRACTED]
  api/Models/Usuario.cs → api/Models/Movimiento.cs
- `AuthController` --references--> `AppDbContext`  [EXTRACTED]
  api/Controllers/AuthController.cs → api/Data/AppDbContext.cs

## Import Cycles
- None detected.

## Communities (49 total, 9 thin omitted)

### Community 0 - "Community 0"
Cohesion: 0.05
Nodes (42): AuthController, AbonoRequest, DeudasController, UsuarioId, InversionesController, UsuarioId, MetasController, UsuarioId (+34 more)

### Community 1 - "Community 1"
Cohesion: 0.05
Nodes (30): Usuario, Email, Id, Movimientos, PasswordHash, build, _cargando, _cargar (+22 more)

### Community 2 - "Community 2"
Cohesion: 0.04
Nodes (28): actual, asistente, build, createState, dashboard, deudas, DrawerRuta, _email (+20 more)

### Community 3 - "Community 3"
Cohesion: 0.05
Nodes (35): cuotaMensual, Deuda, fromJson, id, montoTotal, nombre, proximaFecha, tasaInteres (+27 more)

### Community 4 - "Community 4"
Cohesion: 0.05
Nodes (30): _abrirAbono, _abrirFormulario, build, _cargando, _cargar, createState, _deudas, DeudasScreen (+22 more)

### Community 5 - "Community 5"
Cohesion: 0.17
Nodes (4): FinanzasApi.Data, FinanzasApi.Migrations, FinanzasApi.Controllers, FinanzasApi.Models

### Community 6 - "Community 6"
Cohesion: 0.08
Nodes (15): Init, AgregarDeudas, AgregarPresupuestos, AgregarInversiones, AgregarMetas, AppDbContextModelSnapshot, Deuda, Activa (+7 more)

### Community 7 - "Community 7"
Cohesion: 0.06
Nodes (26): AuthService, login, registrar, alIniciarSesion, autenticarNativo, _controladorExito, _enviarAlBackend, GoogleSignInService (+18 more)

### Community 8 - "Community 8"
Cohesion: 0.10
Nodes (15): _abrirFormulario, build, _cargando, _cargar, createState, _elegirFuenteYEscanear, initState, _movimientos (+7 more)

### Community 9 - "Community 9"
Cohesion: 0.16
Nodes (6): ContextoFinanciero, _es_sospechosa(), escanear_recibo(), preguntar(), ReciboRequest, _validar_llave_y_ritmo()

### Community 10 - "Community 10"
Cohesion: 0.11
Nodes (6): AppDelegate, SceneDelegate, RunnerTests, Flutter, UIKit, XCTest

### Community 11 - "Community 11"
Cohesion: 0.12
Nodes (16): AppColors, ash, bone, carbon, copper, fog, gildedGradient, graphite (+8 more)

### Community 12 - "Community 12"
Cohesion: 0.12
Nodes (14): build, _burbuja, createState, _enviar, _estadoVacio, esUsuario, _inputCtrl, _Mensaje (+6 more)

### Community 13 - "Community 13"
Cohesion: 0.12
Nodes (12): build, _cargando, createState, dispose, _emailCtrl, _enviar, _error, _esRegistro (+4 more)

### Community 14 - "Community 14"
Cohesion: 0.12
Nodes (16): _agregarDigito, _biometricoDisponible, _borrar, _botonTecla, build, createState, _error, initState (+8 more)

### Community 15 - "Community 15"
Cohesion: 0.13
Nodes (15): ASPNETCORE_ENVIRONMENT, applicationUrl, commandName, dotnetRunMessages, environmentVariables, launchBrowser, applicationUrl, commandName (+7 more)

### Community 16 - "Community 16"
Cohesion: 0.12
Nodes (10): AppText, body, bodyStrong, caption, display, eyebrow, heading, statNumber (+2 more)

### Community 17 - "Community 17"
Cohesion: 0.12
Nodes (14): alinear, build, CategoriaGasto, categorias, color, _escalaInferior, _fila, formato (+6 more)

### Community 18 - "Community 18"
Cohesion: 0.13
Nodes (13): ApiClient, baseUrl, cerrarSesion, delete, guardarEmail, guardarToken, _headers, obtenerEmail (+5 more)

### Community 19 - "Community 19"
Cohesion: 0.14
Nodes (12): _activarPin, _biometricoActivo, _biometricoDisponible, build, _cargando, _cargar, createState, _desactivarPin (+4 more)

### Community 20 - "Community 20"
Cohesion: 0.14
Nodes (13): _actual, _agregarDigito, _borrar, _botonTecla, build, _confirmando, createState, _error (+5 more)

### Community 21 - "Community 21"
Cohesion: 0.14
Nodes (11): disablePin, _hash, isBiometricEnabled, isPinEnabled, _kBiometric, _kHash, PinService, setBiometricEnabled (+3 more)

### Community 22 - "Community 22"
Cohesion: 0.15
Nodes (11): _abrirFormulario, build, _cargando, _cargar, createState, _gastadoEnCategoria, initState, _movimientos (+3 more)

### Community 23 - "Community 23"
Cohesion: 0.21
Nodes (10): AppDrawer, _AppDrawerState, AsistenteScreen, _AsistenteScreenState, LoginScreen, _LoginScreenState, DashboardScreen, _DashboardScreenState (+2 more)

### Community 24 - "Community 24"
Cohesion: 0.18
Nodes (11): Movimiento, Categoria, Fecha, Id, Monto, Nota, Tipo, UsuarioId (+3 more)

### Community 25 - "Community 25"
Cohesion: 0.17
Nodes (7): cargar, _clave, establecer, filtroClaro, filtroOscuro, modoClaro, ThemeController

### Community 26 - "Community 26"
Cohesion: 0.18
Nodes (3): buildGoogleButton, buildGoogleButton, main

### Community 27 - "Community 27"
Cohesion: 0.17
Nodes (10): categoria, comercio, DatosRecibo, escanear, fecha, fromJson, _internalKey, monto (+2 more)

### Community 28 - "Community 28"
Cohesion: 0.18
Nodes (8): _anchoMovil, backgroundColor, build, foregroundColor, heroTag, icon, label, onPressed

### Community 29 - "Community 29"
Cohesion: 0.18
Nodes (7): FinancialScoreResult, build, color, paint, progreso, resultado, shouldRepaint

### Community 30 - "Community 30"
Cohesion: 0.18
Nodes (9): categoria, fecha, fromJson, id, monto, Movimiento, nota, tipo (+1 more)

### Community 31 - "Community 31"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 32 - "Community 32"
Cohesion: 0.20
Nodes (9): net10.0, BCrypt.Net-Next (4.2.0), Google.Apis.Auth (1.77.0), Microsoft.AspNetCore.Authentication.JwtBearer (10.0.12), Microsoft.AspNetCore.OpenApi (10.0.12), Microsoft.EntityFrameworkCore.Design (10.0.12), Npgsql.EntityFrameworkCore.PostgreSQL (10.0.3), Swashbuckle.AspNetCore (10.2.3) (+1 more)

### Community 33 - "Community 33"
Cohesion: 0.22
Nodes (4): CurrencyInputFormatter, formatEditUpdate, _formatter, parse

### Community 34 - "Community 34"
Cohesion: 0.25
Nodes (5): alertas, build, _colorBorde, _colorFondo, _icono

### Community 35 - "Community 35"
Cohesion: 0.25
Nodes (4): AsistenteService, _internalKey, preguntar, _url

### Community 36 - "Community 36"
Cohesion: 0.29
Nodes (4): _auth, authenticate, BiometricService, isAvailable

### Community 37 - "Community 37"
Cohesion: 0.29
Nodes (6): ResponsiveFab, AlertasWidget, CategorySpendingChart, _EtiquetaEscala, FinancialScoreWidget, FinoraApp

### Community 38 - "Community 38"
Cohesion: 0.33
Nodes (4): eliminar, guardar, obtenerTodos, PresupuestosService

### Community 39 - "Community 39"
Cohesion: 0.40
Nodes (3): aiBaseUrl, apiBaseUrl, AppConfig

## Knowledge Gaps
- **409 isolated node(s):** `UsuarioId`, `UsuarioId`, `UsuarioId`, `UsuarioId`, `UsuarioId` (+404 more)
  These have ≤1 connection - possible missing edges. (Counts symbols only; 524 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **9 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Usuario` connect `Community 1` to `Community 0`, `Community 24`?**
  _High betweenness centrality (0.176) - this node is a cross-community bridge._
- **What connects `UsuarioId`, `UsuarioId`, `UsuarioId` to the rest of the system?**
  _409 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Community 0` be split into smaller, more focused modules?**
  _Cohesion score 0.05063291139240506 - nodes in this community are weakly interconnected._
- **Why does `AppDbContext` connect `Community 0` to `Community 24`, `Community 1`, `Community 5`, `Community 6`?**
  _High betweenness centrality (0.118) - this node is a cross-community bridge._
- **Should `Community 1` be split into smaller, more focused modules?**
  _Cohesion score 0.047872340425531915 - nodes in this community are weakly interconnected._
- **Why does `Movimiento` connect `Community 24` to `Community 0`, `Community 1`, `Community 6`?**
  _High betweenness centrality (0.060) - this node is a cross-community bridge._
- **Should `Community 2` be split into smaller, more focused modules?**
  _Cohesion score 0.043478260869565216 - nodes in this community are weakly interconnected._