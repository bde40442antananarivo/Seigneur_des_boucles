#!/bin/bash
EXEC="./code/gollum"
ARG="125000,4000000"
REF_FILE="reference.out"
TMP_OUTPUT="output.txt"
FORBIDDEN_FILE="./parameters/forbidden.txt"

echo "🔍 Vérification des fichiers source..."

FILES=$(find . -name "*.c" -o -name "*.h")
if [ -z "$FILES" ]; then
  echo "❌ Aucun fichier source trouvé."
  exit 1
fi

echo "🧹 Vérification de la norme (norminette)..."

norminette $FILES | grep -v "OK!" && echo "❌ Norminette KO" && exit 1
echo "✅ Norminette OK"

if [ ! -f "$FORBIDDEN_FILE" ]; then
  echo "⚠️ Fichier forbidden.txt manquant. Création d’un exemple..."
  echo -e "ngets\nsystem\nstrtok\nstrdup\n" >"$FORBIDDEN_FILE"
fi

echo "⛔ Vérification des fonctions interdites..."

FOUND=0
while IFS= read -r FUNC; do
  # Ignore les lignes vides ou contenant uniquement des espaces
  if [ -n "$(echo "$FUNC" | xargs)" ]; then
    if grep -rnw --include=\*.c --include=\*.h . -e "$FUNC" >/dev/null; then
      echo "❌ Fonction interdite utilisée : $FUNC"
      FOUND=1
    fi
  fi
done <"$FORBIDDEN_FILE"

[ "$FOUND" -eq 1 ] && exit 1
echo "✅ Aucune fonction interdite utilisée."

echo "⚙️ Compilation (si nécessaire)..."
if [ ! -x "$EXEC" ]; then
  echo "🚫 Exécutable $EXEC non trouvé. Compilez manuellement."
  exit 1
fi

IFS=',' read -ra VALUES <<<"$ARG"

for val in "${VALUES[@]}"; do
  val=$(echo "$val" | xargs) # clean all space

  echo "🚀 Exécution avec ARG = $val..."

  START=$(date +%s.%N)
  $EXEC "$val" >"$TMP_OUTPUT"
  END=$(date +%s.%N)
  TIME=$(echo "$END - $START" | bc)

  # Préparer le fichier de référence spécifique
  REF_FILE="./reference/reference_$val.out"
  if [ ! -f "$REF_FILE" ]; then
    echo "⚠️ Fichier de référence '$REF_FILE' manquant."
    exit 1
  fi

  echo "📤 Vérification de la sortie pour ARG = $val..."
  if diff -q "$TMP_OUTPUT" "$REF_FILE" >/dev/null; then
    echo "✅ Résultat correct pour ARG = $val"
  else
    echo "❌ Résultat incorrect pour ARG = $val ! Différences :"
    diff "$TMP_OUTPUT" "$REF_FILE"
    exit 1
  fi

  echo "⏱️ Temps d'exécution : $TIME secondes"
done

echo "🎉 Tous les tests sont PASSÉS !"
