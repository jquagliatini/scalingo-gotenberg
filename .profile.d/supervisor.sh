# L'APT buildpack Scalingo installe les paquets sous /app/.apt/, mais n'ajoute
# pas les modules Python à PYTHONPATH. Sans ça, `supervisord` (script Python
# fourni par le paquet `supervisor`) échoue avec `ModuleNotFoundError: No
# module named 'supervisor'`.

export PYTHONPATH="/app/.apt/usr/lib/python3/dist-packages:${PYTHONPATH:-}"
