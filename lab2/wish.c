#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/wait.h>
#include <unistd.h>

/* =====================================================================
 * CONSTANTES Y VARIABLES GLOBALES
 * ===================================================================== */

char error_message[30] = "An error has occurred\n";

char **search_path = NULL;
int path_count = 0;

/* =====================================================================
 * PROTOTIPOS DE FUNCIONES
 * ===================================================================== */
void print_error();
void init_path();
void free_path();
void builtin_exit(char **args, int argc);
void builtin_cd(char **args, int argc);
void builtin_path(char **args, int argc);
char *find_executable(const char *cmd);
pid_t execute_command(char **args, int argc, char *redirect_file);
void process_line(char *line);

/* =====================================================================
 * FUNCIONES DE UTILIDAD
 * ===================================================================== */

void print_error() {
  write(STDERR_FILENO, error_message, strlen(error_message));
}

void init_path() {
  search_path = malloc(sizeof(char *) * 2);
  search_path[0] = strdup("/bin");
  search_path[1] = NULL;
  path_count = 1;
}

void free_path() {
  for (int i = 0; i < path_count; i++) {
    free(search_path[i]);
  }
  free(search_path);
  search_path = NULL;
  path_count = 0;
}

/* =====================================================================
 * BUILT-IN COMMANDS
 * ===================================================================== */

/*
 * exit: termina el shell. No acepta argumentos.
 */
void builtin_exit(__attribute__((unused)) char **args, int argc) {
  if (argc != 1) {
    print_error();
    return;
  }
  exit(0);
}

/*
 * cd: cambia el directorio de trabajo. Requiere exactamente 1 argumento.
 */
void builtin_cd(char **args, int argc) {
  if (argc != 2) {
    print_error();
    return;
  }
  if (chdir(args[1]) != 0) {
    print_error();
  }
}

/*
 * path: actualiza el search path del shell.
 * Sin argumentos deja el path vacío (ningún externo puede ejecutarse).
 * Siempre sobrescribe el path anterior.
 */
void builtin_path(char **args, int argc) {
  free_path();

  int new_count = argc - 1;

  if (new_count == 0) {
    search_path = malloc(sizeof(char *));
    search_path[0] = NULL;
    path_count = 0;
    return;
  }

  search_path = malloc(sizeof(char *) * (new_count + 1));
  for (int i = 0; i < new_count; i++) {
    search_path[i] = strdup(args[i + 1]);
  }
  search_path[new_count] = NULL;
  path_count = new_count;
}

/* =====================================================================
 * BÚSQUEDA Y EJECUCIÓN DE COMANDOS EXTERNOS
 * ===================================================================== */

/*
 * find_executable: busca 'cmd' en los directorios del search_path.
 * Retorna ruta completa (heap-allocated) o NULL si no se encuentra.
 */
char *find_executable(const char *cmd) {
  char full_path[1024];

  for (int i = 0; i < path_count; i++) {
    snprintf(full_path, sizeof(full_path), "%s/%s", search_path[i], cmd);
    if (access(full_path, X_OK) == 0) {
      return strdup(full_path);
    }
  }
  return NULL;
}

/*
 * execute_command: ejecuta un comando externo con fork()+execv().
 * Retorna el PID del hijo creado, o -1 si no se pudo hacer fork/encontrar el
 * ejecutable. El llamador es responsable de hacer wait() sobre el PID
 * retornado.
 */
pid_t execute_command(char **args, int argc, char *redirect_file) {
  char *exec_path = find_executable(args[0]);
  if (exec_path == NULL) {
    print_error();
    return -1;
  }

  pid_t pid = fork();
  if (pid < 0) {
    print_error();
    free(exec_path);
    return -1;
  }

  if (pid == 0) {
    /* --- PROCESO HIJO --- */
    if (redirect_file != NULL) {
      int fd = open(redirect_file, O_WRONLY | O_CREAT | O_TRUNC, 0644);
      if (fd < 0) {
        print_error();
        exit(1);
      }
      dup2(fd, STDOUT_FILENO);
      dup2(fd, STDERR_FILENO);
      close(fd);
    }

    char **exec_args = malloc(sizeof(char *) * (argc + 1));
    for (int i = 0; i < argc; i++) {
      exec_args[i] = args[i];
    }
    exec_args[argc] = NULL;

    execv(exec_path, exec_args);

    print_error();
    free(exec_args);
    free(exec_path);
    exit(1);
  }

  /* --- PROCESO PADRE --- */
  free(exec_path);
  return pid;
}

/* =====================================================================
 * PROCESAMIENTO DE UNA LÍNEA DE ENTRADA
 * ===================================================================== */

/*
 * parse_single_command: parsea y ejecuta un comando (sin &).
 * Para externos retorna el PID del hijo; para builtins retorna -1.
 */
pid_t parse_single_command(char *cmd_str) {
  char *args[1024];
  int argc = 0;
  char *redirect_file = NULL;
  int found_redirect = 0;
  int error_flag = 0;

  char *token;
  char *rest = cmd_str;

  while ((token = strsep(&rest, " \t")) != NULL) {
    if (strlen(token) == 0)
      continue;

    char *redir_pos = strchr(token, '>');

    if (redir_pos != NULL) {
      if (redir_pos != token) {
        *redir_pos = '\0';
        if (found_redirect) {
          error_flag = 1;
          break;
        }
        args[argc++] = token;
      }

      if (found_redirect) {
        error_flag = 1;
        break;
      }
      found_redirect = 1;

      char *after_redir = redir_pos + 1;
      if (strlen(after_redir) > 0) {
        redirect_file = after_redir;
      }
    } else if (found_redirect) {
      if (redirect_file != NULL) {
        error_flag = 1;
        break;
      }
      redirect_file = token;
    } else {
      args[argc++] = token;
    }
  }

  if (found_redirect && redirect_file == NULL) {
    error_flag = 1;
  }

  if (error_flag) {
    print_error();
    return -1;
  }

  if (argc == 0)
    return -1;

  args[argc] = NULL;

  if (strcmp(args[0], "exit") == 0) {
    builtin_exit(args, argc);
    return -1;
  } else if (strcmp(args[0], "cd") == 0) {
    builtin_cd(args, argc);
    return -1;
  } else if (strcmp(args[0], "path") == 0) {
    builtin_path(args, argc);
    return -1;
  } else {
    return execute_command(args, argc, redirect_file);
  }
}

/*
 * process_line: procesa una línea completa.
 * Divide por '&' para comandos paralelos, lanza todos y luego espera por cada
 * PID.
 */
void process_line(char *line) {
  line[strcspn(line, "\n")] = '\0';

  if (strlen(line) == 0)
    return;

  char *segments[256];
  int seg_count = 0;
  char *rest = line;
  char *seg;

  while ((seg = strsep(&rest, "&")) != NULL) {
    segments[seg_count++] = seg;
  }

  pid_t pids[256];
  int pid_count = 0;

  for (int i = 0; i < seg_count; i++) {
    char *s = segments[i];

    int has_content = 0;
    for (int j = 0; s[j] != '\0'; j++) {
      if (s[j] != ' ' && s[j] != '\t') {
        has_content = 1;
        break;
      }
    }
    if (!has_content)
      continue;

    char s_copy[4096];
    strncpy(s_copy, s, sizeof(s_copy) - 1);
    s_copy[sizeof(s_copy) - 1] = '\0';

    pid_t pid = parse_single_command(s_copy);
    if (pid > 0) {
      pids[pid_count++] = pid;
    }
  }

  /* Esperar a cada hijo por su PID concreto */
  for (int i = 0; i < pid_count; i++) {
    waitpid(pids[i], NULL, 0);
  }
}

/* =====================================================================
 * FUNCIÓN PRINCIPAL
 * ===================================================================== */

int main(int argc, char *argv[]) {
  init_path();

  FILE *input = NULL;
  int interactive = 0;

  if (argc == 1) {
    input = stdin;
    interactive = 1;
  } else if (argc == 2) {
    input = fopen(argv[1], "r");
    if (input == NULL) {
      print_error();
      exit(1);
    }
    interactive = 0;
  } else {
    print_error();
    exit(1);
  }

  char *line = NULL;
  size_t len = 0;
  ssize_t nread;

  while (1) {
    if (interactive) {
      printf("wish> ");
      fflush(stdout);
    }

    nread = getline(&line, &len, input);

    if (nread == -1) {
      free(line);
      if (!interactive)
        fclose(input);
      free_path();
      exit(0);
    }

    process_line(line);
  }

  free(line);
  if (!interactive)
    fclose(input);
  free_path();
  return 0;
}
