library("ggplot2")

full_uma_instancia = read.table("./results/uma_instancia/full.log", header = FALSE, sep = "\t", stringsAsFactors = FALSE)
elephant_uma_instancia = read.table("./results/uma_instancia/elephant.log", header = FALSE, sep = "\t", stringsAsFactors = FALSE)
seahorse_uma_instancia = read.table("./results/uma_instancia/seahorse.log", header = FALSE, sep = "\t", stringsAsFactors = FALSE)
triplesp_uma_instancia = read.table("./results/uma_instancia/triplesp.log", header = FALSE, sep = "\t", stringsAsFactors = FALSE)

full_duas_instancias = read.table("./results/duas_instancias/full.log", header = FALSE, sep = "\t", stringsAsFactors = FALSE)
elephant_duas_instancias = read.table("./results/duas_instancias/elephant.log", header = FALSE, sep = "\t", stringsAsFactors = FALSE)
seahorse_duas_instancias = read.table("./results/duas_instancias/seahorse.log", header = FALSE, sep = "\t", stringsAsFactors = FALSE)
triplesp_duas_instancias = read.table("./results/duas_instancias/triplesp.log", header = FALSE, sep = "\t", stringsAsFactors = FALSE)


fulldata = rbind(
  full_uma_instancia,
  elephant_uma_instancia,
  seahorse_uma_instancia,
  triplesp_uma_instancia,
  full_duas_instancias,
  elephant_duas_instancias,
  seahorse_duas_instancias,
  triplesp_duas_instancias
)

names(fulldata) <- "output_line" 
results <- split(fulldata, f = rep(1:(nrow(fulldata)/16), each = 16))


read_result <- function(df) {
  
  output <- lapply(strsplit(df$output_line, "[ :]"), function(x) x[x != ""])

  instancias <- unlist(strsplit(output[[1]][7],split=","))
  qtdInstancias = length(instancias)
  
  image <- switch(output[[1]][9],
              "-2.500" = {"full"},
              "-0.800" = {"seahorse"},
              "0.175"  = {"elephant"},
               "-0.188" = {"triple_spiral"},
              stop("Image unrecognized.")) 
   nthreads <- as.numeric(output[[1]][13])
   imsize <- as.numeric(output[[1]][14])
   time_elapsed <- as.numeric(gsub(",", "", output[[16]][1]))
   per_stddev <- as.numeric(gsub("%", "",output[[16]][7]))/100
   val_stddev = time_elapsed * per_stddev
   
   results <- data.frame(
     qtdInstancias = qtdInstancias, # Change manually according to GCP setup
     image = image,
     nthreads = nthreads,
     imsize = imsize,
     time_elapsed = time_elapsed,
     per_stddev = per_stddev,
     val_stddev = val_stddev
   )
  
}

results <- do.call("rbind", lapply(results, read_result))


fulldata = rbind(
  results
)

write.csv(fulldata, file = "./results/results.csv")

fig1 <- ggplot(data = fulldata, aes(x = as.factor(qtdInstancias), y = time_elapsed, color = image,group = image)) +
  geom_errorbar(aes(ymin=time_elapsed-val_stddev, ymax=time_elapsed+val_stddev), width=.1) +
  geom_line() +
  geom_point()+
  ggtitle("Média do Tempo de Execução x Quantidade de Instâncias",
          subtitle = "Média com Desvio Padrão") +
  xlab("Quantidade de Instâncias") +
  ylab("Média do Tempo de execução (s)") +
  guides(color = guide_legend(title="Região Processada")) +
  theme(plot.title = element_text(hjust = 0.5, vjust = 5, size = 20),
        strip.text = element_text(size= 16),
        axis.title = element_text(size = 16),
        legend.title = element_text(size = 16),
        legend.text = element_text(size = 16),
        axis.text = element_text(size = 12),
        axis.title.y=element_text(vjust=5),
        axis.title.x=element_text(vjust=-10),
        plot.margin = unit(c(1,1,1,1), "cm"))

pdf("resultados.pdf", width = 16, height = 9)
print(fig1)
dev.off()




#dados <- read.csv("./results/results.csv")
#library("dplyr")

#select(dados, num_hosts, num_threads, img_size, time_elapsed, time_allocation, time_algorithm, time_ioops)

#grouped_result <- group_by(dados, num_hosts, num_threads, img_size)

#summarised_result <- summarise(grouped_result,
#                               media_time_elapsed = mean(time_elapsed, na.rm = TRUE),
#                               desv_pad_time_elapsed = sd(time_elapsed),
#                               media_time_allocation = mean(time_allocation, na.rm = TRUE),
#                               desv_pad_time_allocation = sd(time_allocation),
#                               media_time_algorithm = mean(time_algorithm, na.rm = TRUE),
#                               desv_pad_time_algorithm = sd(time_algorithm),
#                               media_time_ioops = mean(time_ioops, na.rm = TRUE),
#                               desv_pad_time_ioops = sd(time_ioops))


#write.csv(summarised_result, file = "./results/summarised_result.csv")  

#fig2 <- ggplot(data=summarised_result, aes(x = factor(img_size), y=media_time_algorithm, fill=type)) +
#  geom_bar(stat="identity", position=position_dodge())+
  #   facet_wrap(~imsize, scales = "free", labeller = "label_both") +
#  ggtitle("Média do Tempo de Execução x Tamanho da Imagem Pixels") +
#  xlab("Tamanho da Imagem Pixels") +
#  ylab("Tempo de execução (s)") +
#  guides(color = guide_legend(title="Implementação")) +
#  theme(plot.title = element_text(hjust = 0.5, vjust = 5, size = 20),
#        strip.text = element_text(size= 16),
#        axis.title = element_text(size = 16),
#        legend.title = element_text(size = 16),
#        legend.text = element_text(size = 16),
#        axis.text = element_text(size = 12),
#        axis.title.y=element_text(vjust=5),
#        axis.title.x=element_text(vjust=-10),
#        plot.margin = unit(c(1,1,1,1), "cm"))

#pdf("resultado_bar.pdf", width = 16, height = 9)
#print(fig2)
#dev.off() 

 ######################################

# plots <- list()
# current_plot <- 1

# sizes <- unique(results$img_size)
# for (s in sizes) {
#   df <- results[results$img_size == s]
#   plots[[current_plot]] <- list()
#   plots[[current_plot]][["fig"]] <- ggplot(data = df, 
#     aes(x = as.factor(nthreads), y = real, color = algorithm)) +
#     geom_boxplot() +
#     facet_wrap(~image, scales = "free") +
#     ggtitle("Tempo de Execução x Número de Threads", 
#             subtitle = sprintf("Tamanho da imagem: %s (Sem I/O)", s)) +
#     xlab("Número de threads") +
#     ylab("Tempo de execução (s)") +
#     guides(color = guide_legend(title="Implementação")) +
#     theme(plot.title = element_text(hjust = 0.5, vjust = 5, size = 20),
#           plot.subtitle = element_text(hjust = 0.5, size = 14, vjust = 5),
#           strip.text = element_text(size= 16),
#           axis.title = element_text(size = 16),
#           legend.title = element_text(size = 12),
#           legend.text = element_text(size = 12),
#           axis.text = element_text(size = 12),
#           axis.title.y=element_text(vjust=5),
#           axis.title.x=element_text(vjust=-65),
#           plot.margin = unit(c(1,1,1,1), "cm"))
#   plots[[current_plot]][["filename"]] <- sprintf("BoxplotSize%s.pdf", s)
#   current_plot <- current_plot + 1
# }

# for (p in plots) {
#   pdf(paste("./plots/", p[["filename"]], sep = ""), width = 16, height = 9)
#   print(p)
#   dev.off()
# }

# write.csv(results, file = "./results/results.csv")
