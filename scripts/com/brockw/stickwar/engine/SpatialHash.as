package com.brockw.stickwar.engine
{
   import com.brockw.stickwar.engine.units.Wall;
   import flash.utils.Dictionary;
   
   public class SpatialHash
   {
      
      private var partitions:Vector.<Vector.<Entity>>;
      
      private var partitionSizes:Vector.<int>;

      private var activePartitions:Vector.<int>;
      
      private var width:Number;
      
      private var height:Number;
      
      private var boxWidth:Number;
      
      private var boxHeight:Number;
      
      private var cols:int;
      
      private var rows:int;
      
      internal var visited:Dictionary;
      
      internal var game:StickWar;

      private var visitToken:int;
      
      public function SpatialHash(game:StickWar, width:Number, height:Number, boxWidth:Number, boxHeight:Number, maxEntitys:int)
      {
         var x:int = 0;
         super();
         this.game = game;
         this.partitions = new Vector.<Vector.<Entity>>(width / boxWidth * height / boxHeight,false);
         this.partitionSizes = new Vector.<int>(width / boxWidth * height / boxHeight,false);
         this.activePartitions = new Vector.<int>();
         this.visited = new Dictionary();
         this.visitToken = 1;
         this.width = width;
         this.height = height;
         this.boxWidth = boxWidth;
         this.boxHeight = boxHeight;
         this.rows = height / boxHeight;
         this.cols = width / boxWidth;
         for(var y:int = 0; y < this.rows; y++)
         {
            for(x = 0; x < this.cols; x++)
            {
               this.partitions[this.cols * y + x] = new Vector.<Entity>(maxEntitys,false);
               this.partitionSizes[this.cols * y + x] = 0;
            }
         }
      }
      
      public function cleanUp() : void
      {
         var x:int = 0;
         var i:int = 0;
         for(var y:int = 0; y < this.rows; y++)
         {
            for(x = 0; x < this.cols; x++)
            {
               for(i = 0; i < this.partitions[this.cols * y + x].length; i++)
               {
                  this.partitions[this.cols * y + x][i] = null;
               }
               this.partitions[this.cols * y + x] = null;
            }
         }
         this.partitions = null;
         this.partitionSizes = null;
         this.activePartitions = null;
      }
      
      public function add(entity:Entity) : void
      {
         var cellIndex:int = 0;
         var x:int = entity.px / this.boxWidth;
         var y:int = entity.py / this.boxHeight;
         if(x < 0 || x >= this.cols || y < 0 || y >= this.rows)
         {
            return;
         }
         cellIndex = this.cols * y + x;
         this.addToCell(cellIndex,entity);
         if(x > 0)
         {
            this.addToCell(cellIndex - 1,entity);
         }
         if(y > 0)
         {
            this.addToCell(this.cols * (y - 1) + x,entity);
         }
         if(y < this.rows - 1)
         {
            this.addToCell(this.cols * (y + 1) + x,entity);
         }
         if(x < this.cols - 1)
         {
            this.addToCell(cellIndex + 1,entity);
         }
      }
      
      public function mapInArea(xs:Number, ys:Number, xe:Number, ye:Number, f:Function, includeWalls:Boolean = true) : void
      {
         var cellIndex:int = 0;
         var entity:Entity = null;
         var wall:Wall = null;
         var i:int = 0;
         if(includeWalls)
         {
            var lower:Number = Math.min(xs,xe);
            var upper:Number = Math.max(xs,xe);
            for each(wall in this.game.teamA.walls)
            {
               if(wall.px > lower && wall.px < upper)
               {
                  f(wall);
               }
            }
            for each(wall in this.game.teamB.walls)
            {
               if(wall.px > lower && wall.px < upper)
               {
                  f(wall);
               }
            }
         }
         var startX:int = int(Math.floor(Math.min(xs,xe) / this.boxWidth));
         var endX:int = int(Math.ceil(Math.max(xs,xe) / this.boxWidth));
         var startY:int = int(Math.floor(Math.min(ys,ye) / this.boxHeight));
         var endY:int = int(Math.ceil(Math.max(ys,ye) / this.boxHeight));
         if(startX < 0)
         {
            startX = 0;
         }
         if(startY < 0)
         {
            startY = 0;
         }
         if(endX > this.cols)
         {
            endX = this.cols;
         }
         if(endY > this.rows)
         {
            endY = this.rows;
         }
         ++this.visitToken;
         if(this.visitToken == 0)
         {
            this.visitToken = 1;
            this.visited = new Dictionary();
         }
         for(var x:int = startX; x < endX; x++)
         {
            for(var y:int = startY; y < endY; y++)
            {
               cellIndex = this.cols * y + x;
               for(i = 0; i < this.partitionSizes[cellIndex]; i++)
               {
                  entity = this.partitions[cellIndex][i];
                  if(this.visited[entity.id] !== this.visitToken)
                  {
                     f(entity);
                     this.visited[entity.id] = this.visitToken;
                  }
               }
            }
         }
      }
      
      public function getNearbyEntitys(entity:Entity) : Vector.<Entity>
      {
         var x:int = entity.px / this.boxWidth;
         var y:int = entity.py / this.boxHeight;
         if(this.cols * y + x < 0 || this.cols * y + x >= this.partitions.length)
         {
            return new Vector.<Entity>();
         }
         return this.partitions[this.cols * y + x];
      }
      
      public function getNearbyEntitysXY(x:Number, y:Number) : Vector.<Entity>
      {
         x = Math.floor(x / this.boxWidth);
         y = Math.floor(y / this.boxHeight);
         if(this.cols * y + x < 0 || this.cols * y + x >= this.partitions.length)
         {
            return new Vector.<Entity>();
         }
         return this.partitions[this.cols * y + x];
      }
      
      public function getNumberOfNearbyEntitysXY(x:Number, y:Number) : int
      {
         x = Math.floor(x / this.boxWidth);
         y = Math.floor(y / this.boxHeight);
         if(this.cols * y + x < 0 || this.cols * y + x >= this.partitions.length)
         {
            return 0;
         }
         return this.partitionSizes[this.cols * y + x];
      }
      
      public function getNumberOfNearbyEntitys(entity:Entity) : int
      {
         var x:int = entity.px / this.boxWidth;
         var y:int = entity.py / this.boxHeight;
         if(this.cols * y + x < 0 || this.cols * y + x >= this.partitions.length)
         {
            return 0;
         }
         return this.partitionSizes[this.cols * y + x];
      }
      
      public function clear() : void
      {
         var i:int = 0;
         for(i = 0; i < this.activePartitions.length; i++)
         {
            this.partitionSizes[this.activePartitions[i]] = 0;
         }
         this.activePartitions.length = 0;
      }

      private function addToCell(cellIndex:int, entity:Entity) : void
      {
         if(this.partitionSizes[cellIndex] == 0)
         {
            this.activePartitions.push(cellIndex);
         }
         Vector.<Entity>(this.partitions[cellIndex])[this.partitionSizes[cellIndex]] = entity;
         ++this.partitionSizes[cellIndex];
      }
   }
}

